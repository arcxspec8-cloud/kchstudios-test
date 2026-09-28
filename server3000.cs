using System;
using System.IO;
using System.Net;
using System.Threading.Tasks;

class Program {
    static void Main() {
        var listener = new HttpListener();
        listener.Prefixes.Add("http://localhost:3000/");
        listener.Start();
        Console.WriteLine("Server started!");
        Console.WriteLine("Please open: http://localhost:3000/kch-portfolio/index.html");
        
        while (true) {
            var context = listener.GetContext();
            Task.Run(() => ProcessRequest(context));
        }
    }
    
    static void ProcessRequest(HttpListenerContext context) {
        try {
            string urlPath = context.Request.Url.LocalPath.TrimStart('/');
            if (string.IsNullOrEmpty(urlPath)) urlPath = "kch-portfolio/index.html";
            
            string localPath = Path.Combine(Environment.CurrentDirectory, urlPath.Replace("/", "\\"));
            if (Directory.Exists(localPath)) {
                localPath = Path.Combine(localPath, "index.html");
            }
            
            if (File.Exists(localPath)) {
                string ext = Path.GetExtension(localPath).ToLower();
                string mime = "application/octet-stream";
                if (ext == ".html") mime = "text/html; charset=utf-8";
                else if (ext == ".css") mime = "text/css";
                else if (ext == ".js") mime = "application/javascript";
                else if (ext == ".png") mime = "image/png";
                else if (ext == ".jpg" || ext == ".jpeg") mime = "image/jpeg";
                else if (ext == ".svg") mime = "image/svg+xml";
                else if (ext == ".woff") mime = "font/woff";
                else if (ext == ".woff2") mime = "font/woff2";
                else if (ext == ".ico") mime = "image/x-icon";
                
                context.Response.ContentType = mime;
                context.Response.Headers.Add("Access-Control-Allow-Origin", "*");
                byte[] bytes = File.ReadAllBytes(localPath);
                context.Response.ContentLength64 = bytes.Length;
                context.Response.OutputStream.Write(bytes, 0, bytes.Length);
            } else {
                context.Response.StatusCode = 404;
            }
        } catch {
            try { context.Response.StatusCode = 500; } catch {}
        } finally {
            try { context.Response.Close(); } catch {}
        }
    }
}
