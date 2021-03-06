﻿using System.Drawing;
using System.Windows.Forms;
using CefSharp;
using TweetDuck.Controls;
using TweetDuck.Dialogs;
using TweetDuck.Utils;

namespace TweetDuck.Browser.Handling.General{
    sealed class JavaScriptDialogHandler : IJsDialogHandler{
        private static FormMessage CreateMessageForm(string caption, string text){
            MessageBoxIcon icon = MessageBoxIcon.None;
            int pipe = text.IndexOf('|');

            if (pipe != -1){
                icon = text.Substring(0, pipe) switch{
                    "error"    => MessageBoxIcon.Error,
                    "warning"  => MessageBoxIcon.Warning,
                    "info"     => MessageBoxIcon.Information,
                    "question" => MessageBoxIcon.Question,
                    _          => MessageBoxIcon.None
                };

                if (icon != MessageBoxIcon.None){
                    text = text.Substring(pipe + 1);
                }
            }

            return new FormMessage(caption, text, icon);
        }

        bool IJsDialogHandler.OnJSDialog(IWebBrowser browserControl, IBrowser browser, string originUrl, CefJsDialogType dialogType, string messageText, string defaultPromptText, IJsDialogCallback callback, ref bool suppressMessage){
            browserControl.AsControl().InvokeSafe(() => {
                FormMessage form;
                TextBox input = null;

                if (dialogType == CefJsDialogType.Alert){
                    form = CreateMessageForm("Browser Message", messageText);
                    form.AddButton(FormMessage.OK, ControlType.Accept | ControlType.Focused);
                }
                else if (dialogType == CefJsDialogType.Confirm){
                    form = CreateMessageForm("Browser Confirmation", messageText);
                    form.AddButton(FormMessage.No, DialogResult.No, ControlType.Cancel);
                    form.AddButton(FormMessage.Yes, ControlType.Focused);
                }
                else if (dialogType == CefJsDialogType.Prompt){
                    form = CreateMessageForm("Browser Prompt", messageText);
                    form.AddButton(FormMessage.Cancel, DialogResult.Cancel, ControlType.Cancel);
                    form.AddButton(FormMessage.OK, ControlType.Accept | ControlType.Focused);

                    float dpiScale = form.GetDPIScale();
                    int inputPad = form.HasIcon ? 43 : 0;

                    input = new TextBox{
                        Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom,
                        Font = SystemFonts.MessageBoxFont,
                        Location = new Point(BrowserUtils.Scale(22 + inputPad, dpiScale), form.ActionPanelY - BrowserUtils.Scale(46, dpiScale)),
                        Size = new Size(form.ClientSize.Width - BrowserUtils.Scale(44 + inputPad, dpiScale), BrowserUtils.Scale(23, dpiScale))
                    };

                    form.Controls.Add(input);
                    form.ActiveControl = input;
                    form.Height += input.Size.Height + input.Margin.Vertical;
                }
                else{
                    callback.Continue(false);
                    return;
                }

                bool success = form.ShowDialog() == DialogResult.OK;

                if (input == null){
                    callback.Continue(success);
                }
                else{
                    callback.Continue(success, input.Text);
                    input.Dispose();
                }

                form.Dispose();
            });

            return true;
        }

        bool IJsDialogHandler.OnBeforeUnloadDialog(IWebBrowser browserControl, IBrowser browser, string messageText, bool isReload, IJsDialogCallback callback){
            callback.Dispose();
            return false;
        }

        void IJsDialogHandler.OnResetDialogState(IWebBrowser browserControl, IBrowser browser){}
        void IJsDialogHandler.OnDialogClosed(IWebBrowser browserControl, IBrowser browser){}
    }
}
