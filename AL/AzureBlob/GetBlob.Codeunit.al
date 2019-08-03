codeunit 60203 "Get Azure Blob"
{
    procedure GetBlob(VAR TempBlob: Record Tempblob temporary; AccountName: Text; AccountContainer: Text; AccountPrivateKey: Text; BlobUrl: Text) ContentLength: Integer
    var
        HMACSHA256Mgt: Codeunit "HMACSHA256 Management";
        WebRequest: HttpRequestMessage;
        WebResponse: HttpResponseMessage;
        WebContent: HttpContent;
        WebHeaders: HttpHeaders;
        WebClient: HttpClient;
        OutStr: OutStream;
        InStr: InStream;
        CanonicalizedHeaders: Text;
        CanonicalizedResource: Text;
        Authorization: Text;
    begin
        Initialize(AccountName);
        if StrPos(BlobUrl, ContainerUrl) <> 1 then error(FailedToGetBlobErr + UrlIncorrectErr);
        BlobUrl := CopyStr(BlobUrl, StrLen(ContainerUrl) + 1);

        CanonicalizedHeaders := 'x-ms-date:' + UTCDateTimeText + NewLine + 'x-ms-version:2015-02-21';
        CanonicalizedResource := StrSubstNo('/%1/%2', AccountName, BlobUrl);
        Authorization := HMACSHA256Mgt.GetAuthorization(AccountName, AccountPrivateKey, HMACSHA256Mgt.GetTextToHash('GET', '', CanonicalizedHeaders, CanonicalizedResource, ''));

        WebRequest.SetRequestUri(ContainerUrl + BlobUrl);
        WebRequest.Method('GET');
        WebRequest.GetHeaders(WebHeaders);
        WebHeaders.Add('Authorization', Authorization);
        WebHeaders.Add('x-ms-date', UTCDateTimeText);
        WebHeaders.Add('x-ms-version', '2015-02-21');
        WebClient.Send(WebRequest, WebResponse);
        if not WebResponse.IsSuccessStatusCode then
            error(FailedToGetBlobErr + WebResponse.ReasonPhrase);
        WebContent := WebResponse.Content;
        CreateResponseStream(InStr);
        WebContent.ReadAs(InStr);
        TempBlob.Blob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        exit(TempBlob.Blob.Length);
    end;

    local procedure CreateResponseStream(var InStr: Instream)
    var
        TempBlob: Record TempBlob;
    begin
        TempBlob.Blob.CreateInStream(InStr);
    end;

    local procedure Initialize(AccountName: Text)
    var
        UTCDateTimeMgt: Codeunit "UTC DateTime Management";
    begin
        NewLine[1] := 10;
        UTCDateTimeText := UTCDateTimeMgt.GetUTCDateTimeText();
        ContainerUrl := 'https://' + AccountName + '.blob.core.windows.net/';
    end;

    var
        FailedToGetBlobErr: Label 'Failed to download a blob: ';
        UrlIncorrectErr: Label 'Url incorrect.';
        UTCDateTimeText: Text;
        ContainerUrl: Text;
        NewLine: Text[1];
}