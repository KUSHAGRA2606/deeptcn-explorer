"""Post-export polish for the shinylive index.html: title, description and a dark
loading splash that hides itself once the Shiny navbar appears inside the iframe."""
import re
import sys

path = sys.argv[1]
s = open(path, encoding="utf-8").read()
s = re.sub(r"<title>.*?</title>", "<title>DeepTCN Explorer</title>", s, count=1, flags=re.S)

head_extra = """
    <meta name="description" content="Interactive explainer for DeepTCN probabilistic forecasting and four extensions (DA3041, IIT Guwahati). Built in R with shiny; runs in the browser via webR.">
    <style>
      html,body{background:#0a1020;margin:0}
      #splash{position:fixed;inset:0;z-index:50;display:flex;flex-direction:column;align-items:center;justify-content:center;
              background:radial-gradient(circle at 50% 40%,#13254a 0%,#0a1020 60%);color:#e2e8f0;
              font-family:'Segoe UI',Inter,Arial,sans-serif;transition:opacity .6s ease}
      #splash h1{font-size:2.2rem;margin:0 0 6px;font-weight:800;letter-spacing:-.5px}
      #splash p{color:#94a3b8;margin:4px 0}
      #splash .bar{width:260px;height:6px;border-radius:99px;background:#1e293b;overflow:hidden;margin:18px 0 10px}
      #splash .bar i{display:block;height:100%;width:40%;border-radius:99px;
              background:linear-gradient(90deg,#38bdf8,#a78bfa);animation:slide 1.4s ease-in-out infinite}
      @keyframes slide{0%{transform:translateX(-110%)}100%{transform:translateX(260%)}}
      #splash.hide{opacity:0;pointer-events:none}
    </style>
"""
splash = """
    <div id="splash">
      <h1>DeepTCN Explorer</h1>
      <p>Starting R inside your browser&hellip;</p>
      <div class="bar"><i></i></div>
      <p style="font-size:.9rem">First visit takes about 30&ndash;60 seconds. No server, no install.</p>
    </div>
    <script>
      (function () {
        var t = setInterval(function () {
          var f = document.querySelector("iframe");
          try {
            if (f && f.contentDocument && f.contentDocument.querySelector(".navbar")) {
              document.getElementById("splash").classList.add("hide");
              clearInterval(t);
            }
          } catch (e) {}
        }, 500);
      })();
    </script>
"""
if 'id="splash"' not in s:
    s = s.replace("</head>", head_extra + "  </head>", 1)
    s = s.replace("<body>", "<body>" + splash, 1)
open(path, "w", encoding="utf-8").write(s)
print("patched", path)
