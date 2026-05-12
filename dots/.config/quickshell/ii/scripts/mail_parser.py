#!/usr/bin/env python3
import sys
import email
from email import policy
import base64
import re
import urllib.parse

try:
    from bs4 import BeautifulSoup
except ImportError:
    BeautifulSoup = None

def fix_colors(html):
    """Fix common hex color issues like '101010' instead of '#101010'"""
    # Fix hex colors missing #
    def add_hash(match):
        hex_val = match.group(1)
        if len(hex_val) in [3, 6, 8]:
            return f'color: #{hex_val}'
        return match.group(0)
    
    html = re.sub(r'color:\s*([0-9a-fA-F]{3,8})', add_hash, html)
    html = re.sub(r'bgcolor=["\']([0-9a-fA-F]{3,8})["\']', r'bgcolor="#\1"', html)
    html = html.replace('color: #fffff;', 'color: #ffffff;')
    html = html.replace('color: #fffff"', 'color: #ffffff"')
    return html

def parse_email(raw_data, bg_color=None, fg_color=None):
    try:
        # Debug marker
        debug_info = "<!-- VYNX-MAIL-PARSER-v6 -->"
        
        msg = email.message_from_bytes(raw_data, policy=policy.default)
        
        parts_by_cid = {}
        html_body = None
        text_body = None
        
        # First pass: find all parts and CIDs
        for part in msg.walk():
            cid = part.get("Content-ID")
            if cid:
                cid = cid.strip("<>")
                parts_by_cid[cid] = part
                
            content_type = part.get_content_type()
            disposition = str(part.get_content_disposition())
            
            if content_type == "text/html" and "attachment" not in disposition:
                if html_body is None:
                    payload = part.get_payload(decode=True)
                    charset = part.get_content_charset() or 'utf-8'
                    try:
                        html_body = payload.decode(charset, errors='replace')
                    except:
                        html_body = payload.decode('latin-1', errors='replace')
            elif content_type == "text/plain" and "attachment" not in disposition:
                if text_body is None:
                    payload = part.get_payload(decode=True)
                    charset = part.get_content_charset() or 'utf-8'
                    try:
                        text_body = payload.decode(charset, errors='replace')
                    except:
                        text_body = payload.decode('latin-1', errors='replace')

        if html_body:
            # Pre-processing: replace cid: references
            def replace_cid_match(match):
                attr = match.group(1)
                cid = match.group(2)
                if cid in parts_by_cid:
                    part = parts_by_cid[cid]
                    content_type = part.get_content_type()
                    payload = part.get_payload(decode=True)
                    if payload:
                        data = base64.b64encode(payload).decode('utf-8')
                        return f'{attr}="data:{content_type};base64,{data}"'
                return match.group(0)

            html_body = re.sub(r'(\w+)=["\']cid:([^"\'\s>]+)["\']', replace_cid_match, html_body, flags=re.IGNORECASE)
            html_body = fix_colors(html_body)
            
            if BeautifulSoup:
                soup = BeautifulSoup(html_body, 'html.parser')
                
                # NORMALIZATION: Remove everything that isn't content or basic structure
                for tag in soup(['script', 'iframe', 'object', 'embed', 'meta', 'link', 'video', 'audio', 'head']):
                    tag.decompose()
                
                # Strip ALL style tags
                for tag in soup.find_all('style'):
                    tag.decompose()

                # Normalization Styles for QML RichText
                norm_style = soup.new_tag('style')
                norm_style.string = """
                    body { font-family: sans-serif; line-height: 1.4; }
                    img { display: block; max-width: 100%; height: auto; margin: 10px 0; }
                    p { margin: 10px 0; display: block; }
                    div { display: block; }
                    table { width: 100%; border-collapse: collapse; }
                """
                
                # Process all tags
                for tag in soup.find_all(True):
                    # Aggressively strip background and text colors to let theme take over
                    for attr in ['bgcolor', 'background', 'color']:
                        if attr in tag.attrs:
                            del tag.attrs[attr]

                    if 'style' in tag.attrs:
                        style = tag.attrs['style'].lower()
                        allowed_styles = []
                        for part in style.split(';'):
                            part = part.strip()
                            if not part: continue
                            
                            # Block layout busters
                            if any(x in part for x in ['float', 'position', 'flex', 'grid', 'fixed', 'absolute', 'top', 'bottom', 'left', 'right', 'z-index']):
                                continue
                            
                            # STRIP colors and backgrounds from elements
                            if any(x in part for x in ['background-color', 'background', 'color:']):
                                continue
                                
                            if any(x in part for x in ['font', 'text-align', 'margin', 'padding', 'width', 'height', 'border']):
                                allowed_styles.append(part)
                        
                        tag.attrs['style'] = "; ".join(allowed_styles)

                    # Image Overlap Fix
                    if tag.name == 'img':
                        for attr in list(tag.attrs.keys()):
                            if attr not in ['src', 'width', 'height', 'alt']:
                                del tag.attrs[attr]
                        
                        wrapper = soup.new_tag('div')
                        wrapper.attrs['style'] = "display: block; margin: 15px 0; width: 100%;"
                        tag.wrap(wrapper)
                        wrapper.insert_before(soup.new_tag('br'))
                        wrapper.insert_after(soup.new_tag('br'))

                # Final assembly with theme colors
                content = str(soup)
                # Apply theme colors ONLY to the body
                theme_style = f"background-color: {bg_color or '#000000'}; color: {fg_color or '#ffffff'}; margin: 15px;"
                
                return f'<html><head>{str(norm_style)}</head><body style="{theme_style}">{debug_info}{content}</body></html>'
            else:
                # Regex fallback
                notice = "<div style='color: #ff0000; font-weight: bold;'>BeautifulSoup4 missing!</div>"
                html_body = re.sub(r'<(script|iframe|style|link|meta|head)[^>]*>.*?</\1>', '', html_body, flags=re.DOTALL | re.IGNORECASE)
                html_body = re.sub(r'<img([^>]+)>', r'<br><div style="display:block;margin:15px 0;"><img\1></div><br>', html_body, flags=re.IGNORECASE)
                html_body = re.sub(r'(float|position|flex|grid|fixed|absolute|background|color)\s*:\s*[^;"]+;?', '', html_body, flags=re.IGNORECASE)
                
                return f'<html><body style="background-color: {bg_color or "#000000"}; color: {fg_color or "#ffffff"}; padding: 15px;">{debug_info}{notice}{html_body}</body></html>'
        
        if text_body:
            escaped = text_body.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            html_text = escaped.replace("\n", "<br>")
            wrapper_style = f"white-space: pre-wrap; background-color: {bg_color or '#000000'}; color: {fg_color or '#ffffff'}; padding: 15px; font-family: monospace;"
            return f'<html><body><div style="{wrapper_style}">{debug_info}{html_text}</div></body></html>'
            
        return f"<html><body>{debug_info}No content found</body></html>"
    except Exception as e:
        import traceback
        err = traceback.format_exc()
        return f"<html><body><h3>Error parsing email</h3><pre>{err}</pre></body></html>"

if __name__ == "__main__":
    bg = None
    fg = None
    if len(sys.argv) > 1:
        # Improved color detection: if it looks like a hex or starts with #
        arg1 = sys.argv[1]
        if arg1.startswith('#') or re.match(r'^[0-9a-fA-F]{3,8}$', arg1):
            bg = arg1 if arg1.startswith('#') else f'#{arg1}'
            if len(sys.argv) > 2:
                arg2 = sys.argv[2]
                fg = arg2 if arg2.startswith('#') else f'#{arg2}'
            raw_data = sys.stdin.buffer.read()
            print(parse_email(raw_data, bg, fg))
        else:
            file_path = sys.argv[1]
            if len(sys.argv) > 2:
                bg = sys.argv[2]
            if len(sys.argv) > 3:
                fg = sys.argv[3]
            try:
                with open(file_path, 'rb') as f:
                    print(parse_email(f.read(), bg, fg))
            except Exception as e:
                print(f"<html><body>Error reading file: {str(e)}</body></html>")
    else:
        raw_data = sys.stdin.buffer.read()
        print(parse_email(raw_data))
