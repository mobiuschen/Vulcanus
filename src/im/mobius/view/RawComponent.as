package im.mobius.view
{
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

public class RawComponent
{
    public function RawComponent()
    {
    }
    
    static public function createBtn(txt:String):Sprite
    {
        var btn:Sprite = new Sprite();
        var tf:TextField = new TextField();
        var format:TextFormat = new TextFormat(null, 16, 0xffffff);
        format.align = TextFormatAlign.CENTER;
        tf.defaultTextFormat = format;
        tf.background = true;
        tf.backgroundColor = 0xAAAAAA;
        tf.text = txt;
        tf.width = Math.ceil(tf.textWidth / 50) * 50;
        tf.height = 25;
        btn.addChild(tf);
        btn.mouseChildren = false;
        return btn;
    }
}
}