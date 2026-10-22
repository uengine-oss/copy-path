from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import subprocess, math
ROOT=Path(__file__).resolve().parent
W,H=1280,720
font='/Users/uengine/Library/Fonts/NotoSansCJKkr-Regular.otf'
bold='/Users/uengine/Library/Fonts/NotoSansCJKkr-Bold.otf'
def f(n,b=False): return ImageFont.truetype(bold if b else font,n)
scenes=[
('Windows 11 · Copy Path','경로 복사부터 최근 파일 열기까지', 'Copy Path   /   Recent Paths   /   Open Paths'),
('01  압축 해제 후 설치','ZIP 파일을 압축 해제하고 Install.cmd를 실행하세요.', '관리자 권한 없이 현재 사용자 계정에 설치됩니다.'),
('02  기존 우클릭 메뉴 열기','파일이나 폴더 우클릭 → 더 많은 옵션 표시', 'Windows 11의 첫 메뉴가 아닌 기존 메뉴에 표시됩니다.'),
('03  전체 경로 복사','Copy Path를 클릭하면 절대경로가 복사됩니다.', '붙여넣을 곳에서 Ctrl + V · 성공 알림이나 소리는 없습니다.'),
('04  최근 경로 다시 복사','Recent Paths에서 원하는 항목을 클릭하세요.', '최근 10개 · 파일명과 짧은 경로 표시 · 전체 경로 복사'),
('05  최근 파일·폴더 바로 열기','Open Paths에서 원하는 항목을 클릭하세요.', '파일은 기본 앱으로, 폴더는 탐색기로 열립니다.'),
('설치와 사용, 한눈에','압축 해제 → Install.cmd → 우클릭 → 더 많은 옵션 표시', '삭제할 때는 Uninstall.cmd를 실행하세요.')]
BG='#0d1424'; WHITE='#f5f7ff'; MUTED='#adb9cf'; BLUE='#75a6ff'
def text(d,xy,s,size=24,color=WHITE,b=False): d.text(xy,s,font=f(size,b),fill=color)
def box(d,rect,fill='#ffffff',outline=None,r=16): d.rounded_rectangle(rect,radius=r,fill=fill,outline=outline,width=2)
def menu(d,x,y,items,selected=None,width=290):
    box(d,(x,y,x+width,y+len(items)*43+16),'#ffffff','#dce2ed',10)
    for i,s in enumerate(items):
        if i==selected: box(d,(x+6,y+8+i*43,x+width-6,y+49+i*43),'#dceaff',r=5)
        text(d,(x+18,y+14+i*43),s,19,'#253149')
def frame(scene,t):
    im=Image.new('RGB',(W,H),BG);d=ImageDraw.Draw(im)
    title,subtitle,note=scenes[scene]
    text(d,(50,26),'COPY PATH  /  WINDOWS 11',17,BLUE,True)
    text(d,(930,28),'설명용 재현 화면 · 무음 안내',16,MUTED)
    text(d,(50,70),title,36,WHITE,True)
    text(d,(52,124),subtitle,23,MUTED)
    box(d,(50,185,1230,580),'#edf2fa',r=18)
    text(d,(78,203),'파일 탐색기    >    문서',18,'#465773')
    d.line((70,243,1210,243),fill='#d6deeb',width=2)
    if scene==0:
        for i,(label,desc) in enumerate([('Copy Path','절대경로 복사'),('Recent Paths','최근 경로 재복사'),('Open Paths','파일·폴더 열기')]):
            x=90+i*370;box(d,(x,290,x+345,490),'#ffffff')
            text(d,(x+24,325),label,29,'#2055a6',True);text(d,(x+24,395),desc,22,'#465773')
    elif scene==1:
        text(d,(90,270),'CopyPathWindows',24,'#253149',True)
        for i,label in enumerate(['Install.cmd','CopyPath.ps1','Uninstall.cmd','README.txt']):
            y=320+i*49
            if i==0:box(d,(80,y-5,650,y+38),'#dceaff',r=5)
            text(d,(104,y),label,23,'#253149',i==0)
        box(d,(740,316,1160,465),'#e1eaff')
        text(d,(768,340),'Install.cmd 실행',27,'#2055a6',True)
        text(d,(768,393),'설치 완료 문구를 확인하세요.',21,'#465773')
    elif scene==2:
        box(d,(80,270,495,318),'#dceaff',r=5);text(d,(100,279),'업무 보고서.docx',23,'#253149')
        menu(d,480,274,['열기','다음으로 열기','압축 파일로 압축','속성','더 많은 옵션 표시'],4,340)
        text(d,(865,335),'여기를 선택',23,'#2055a6',True)
        text(d,(865,385),'또는 Shift + F10',21,'#465773')
    elif scene in (3,4,5):
        box(d,(80,270,420,318),'#dceaff',r=5);text(d,(99,278),'업무 보고서.docx',23,'#253149')
        menu(d,105,330,['Copy Path','Recent Paths  ›','Open Paths    ›'],scene-3,285)
        if scene==3:
            box(d,(465,300,1175,480),'#ffffff')
            text(d,(492,325),'Ctrl + V로 붙여넣기',23,'#2055a6',True)
            text(d,(492,390),'C:\\Users\\User\\Documents\\업무 보고서.docx',21,'#253149')
        else:
            menu(d,398,345,['업무 보고서.docx — C:\\Users\\User…','프로젝트 자료 — C:\\Users\\User…','견적서.xlsx — C:\\Users\\User…'],0,625)
            if scene==5 and t>2.5:
                box(d,(460,270,1155,517),'#ffffff','#9bbcf4')
                text(d,(486,290),'업무 보고서.docx  |  기본 앱',23,'#2055a6',True)
                for j in range(4):d.line((488,355+j*30,1070-j%2*130,355+j*30),fill='#d9e2f0',width=8)
    else:
        rows=[('Copy Path','현재 선택한 파일·폴더의 경로 복사'),('Recent Paths','최근 경로 10개를 다시 복사'),('Open Paths','최근 파일·폴더를 바로 열기')]
        for i,(label,desc) in enumerate(rows):
            y=279+i*78;text(d,(100,y),label,27,'#2055a6',True);text(d,(400,y+3),desc,25,'#253149')
        text(d,(100,530),'이 패키지는 실제 Windows 실행 검증 전 버전입니다.',18,'#6b7280')
    text(d,(52,610),note,22,WHITE)
    if scene in (1,2,3,4,5):
        targets={1:(370,343),2:(760,476),3:(330,358),4:(870,371),5:(870,371)}
        x,y=targets[scene]; x+=int(18*max(0,1-t));y+=int(18*max(0,1-t))
        if 1<t<2:
            radius=int(18+15*(t-1)); d.ellipse((x-radius,y-radius,x+radius,y+radius),outline='#4184ed',width=3)
        d.polygon([(x,y),(x+4,y+28),(x+12,y+20),(x+22,y+21)],fill='#152641',outline='white')
    text(d,(1130,614),f'{scene+1} / 7',20,MUTED)
    d.rounded_rectangle((50,676,1230,682),radius=3,fill='#26344d')
    d.rounded_rectangle((50,676,50+int(1180*(scene+t/5)/7),682),radius=3,fill=BLUE)
    return im
out=ROOT/'CopyPath-Windows11-사용법.mp4'
proc=subprocess.Popen(['/opt/homebrew/bin/ffmpeg','-y','-f','rawvideo','-vcodec','rawvideo','-pix_fmt','rgb24','-s','1280x720','-r','24','-i','-','-an','-c:v','libx264','-preset','fast','-crf','21','-pix_fmt','yuv420p','-movflags','+faststart',str(out)],stdin=subprocess.PIPE,stderr=open(ROOT/'encode.log','w'))
for scene in range(7):
    for i in range(120):proc.stdin.write(frame(scene,i/24).tobytes())
proc.stdin.close()
assert proc.wait()==0
frame(4,1.5).save(ROOT/'preview.png')
print(out)
