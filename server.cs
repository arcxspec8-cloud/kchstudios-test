using System;
using System.IO;
using System.Net;
using System.Threading.Tasks;

class Program {
    static void Main() {
        var listener = new HttpListener();
        listener.Prefixes.Add("http://localhost:8080/");
        listener.Start();
        Console.WriteLine("Server started!");
        Console.WriteLine("Please open: http://localhost:8080/haus-portfolio-template.webflow.io/");
        
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
                if (ext == ".html") mime = "text/html";
                else if (ext == ".css") mime = "text/css";
                else if (ext == ".js") mime = "application/javascript";
                else if (ext == ".png") mime = "image/png";
                else if (ext == ".jpg" || ext == ".jpeg") mime = "image/jpeg";
                else if (ext == ".svg") mime = "image/svg+xml";
                else if (ext == ".woff") mime = "font/woff";
                else if (ext == ".woff2") mime = "font/woff2";
                
                context.Response.ContentType = mime;
                byte[] bytes = File.ReadAllBytes(localPath);
                context.Response.ContentLength64 = bytes.Length;
                context.Response.OutputStream.Write(bytes, 0, bytes.Length);
            } else {
                context.Response.StatusCode = 404;
            }
        } catch {
            context.Response.StatusCode = 500;
        } finally {
            context.Response.Close();
        }
    }
}
