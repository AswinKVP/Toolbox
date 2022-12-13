/*
Replace all instances of a JSON element (key) across all paths inside a JSON document
=====================================================================================
Author: Eitan Blumin
Date: 2022-12-13
Description:
	Normally, when you want to replace/update a JSON element in SQL Server, you must specify
	for the JSON_MODIFY function an explicit path which would be affected.
	But this wouldn't be possible if you don't necessarily know in advance the JSON path
	where the relevant element/key is located.

	This is the purpose of this stored procedure. It will recursively traverse across all paths
	inside the specified JSON document, and find all keys matching the specified element to find.
	And finally, all of the discovered paths would be replaced with the replacement value specified.


Example execution:

DECLARE
	  @JDoc nvarchar(MAX) = N'{    "screen": {      "content": {        "type": "List",        "items": [          {            "row": [              {                "type": "empty",                "height": "5vh"              }            ]          },          {            "row": [              {                "type": "label",                "text": "Verify your account info",                "color": "#000000",                "font_size": "27px",                "font_weight": "bold"              }            ]          },          {            "row": [              {                "type": "empty",                "height": "1vh"              }            ]          },          {            "row": [              {                "type": "table",                "text_align": "left",                "table": {                  "first_item": "Policy Number",                  "top_item": "",                  "bottom_item": "",                  "last_item": "12354568"                },                "font_size": "14px"              }            ]          },          {            "row": [              {                "type": "separator",                "border_top_color": "#C0C0C0",                "border_top_style": "solid",                "border_top_width": "1px"              }            ]          },          {            "row": [              {                "type": "table",                "text_align": "left",                "table": {                  "first_item": "Driver 1",                  "top_item": "",                  "bottom_item": "",                  "last_item": "Jim Davis"                },                "font_size": "14px"              }            ]          },          {            "row": [              {                "type": "separator",                "border_top_color": "#C0C0C0",                "border_top_style": "solid",                "border_top_width": "1px"              }            ]          },          {            "row": [              {                "type": "table",                "text_align": "left",                "table": {                  "first_item": "Driver 2",                  "top_item": "",                  "bottom_item": "",                  "last_item": "Natalie Davis"                },                "font_size": "14px"              }            ]          },          {            "row": [              {                "type": "separator",                "border_top_color": "#C0C0C0",                "border_top_style": "solid",                "border_top_width": "1px"              }            ]          },          {            "row": [              {                "type": "table",                "text_align": "left",                "table": {                  "first_item": "Adress",                  "top_item": "",                  "bottom_item": "",                  "last_item": "522 Pine St"                },                "font_size": "14px"              }            ]          },          {            "row": [              {                "type": "separator",                "border_top_color": "#C0C0C0",                "border_top_style": "solid",                "border_top_width": "1px"              }            ]          },          {            "row": [              {                "type": "table",                "text_align": "left",                "table": {                  "first_item": "City",                  "top_item": "",                  "bottom_item": "",                  "last_item": "San Francisco"                },                "font_size": "14px"              }            ]          },          {            "row": [              {                "type": "separator",                "border_top_color": "#C0C0C0",                "border_top_style": "solid",                "border_top_width": "1px"              }            ]          },          {            "row": [              {                "type": "table",                "text_align": "left",                "table": {                  "first_item": "State, Zip",                  "top_item": "",                  "bottom_item": "",                  "last_item": "CA, 90001"                },                "font_size": "14px"              }            ]          },          {            "row": [              {                "type": "empty",                "height": "20vh"              }            ]          },          {            "row": [              {                "type": "action_button",                "background": "#09374E",                "text": "Next",                "color": "#ffffff",                "font_size": "16px",                "font_weight": "bold",                "text_align": "center",                "align": "center",                "action": "submit_value",                "width": "100%",                "submit_val": "njaeaq"              }            ]          }        ]      },      "alignment": "left",      "screen_category": "",      "screen_name": "newScreen1",      "header": {        "background": "#09374E",        "logo_alignment": "center"      },      "app_icon": "./static/img/logo/insurance.svg",      "back_button": {        "submit_val": "back",        "color": "#ffffff",        "font_size": "25px"      }    }  }'
	, @jElementToFind nvarchar(4000) = N'background'
	, @jReplacementValue nvarchar(MAX) = NULL --N'RED'
	, @Verbose bit = 1

EXEC PROC_ReplaceJsonElementInAllPaths
	@JDoc OUTPUT, @jElementToFind, @jReplacementValue, @Verbose

SELECT @JDoc AS NewValue

*/
CREATE PROCEDURE PROC_ReplaceJsonElementInAllPaths
	  @JDoc nvarchar(MAX) OUTPUT
	, @jElementToFind nvarchar(4000)
	, @jReplacementValue nvarchar(MAX) = NULL
	, @Verbose bit = 0
AS
SET NOCOUNT ON;

IF @JDoc IS NULL OR @jElementToFind IS NULL
BEGIN
	IF @Verbose = 1 RAISERROR(N'Nothing to replace',0,1) WITH NOWAIT;
	RETURN;
END

DECLARE @Paths AS table(jpath nvarchar(4000) NOT NULL);

DECLARE @CurrPaths AS table (jkey sysname, jvalue nvarchar(MAX) NULL, jtype int, jpath nvarchar(4000) NULL);
INSERT INTO @CurrPaths (jkey, jvalue, jtype, jpath)
SELECT N'$', @JDoc, 5, N'$'

WHILE 1=1
BEGIN
	DECLARE @CurrPath nvarchar(4000), @CurrType int
	SELECT TOP (1) @CurrPath = jpath, @CurrType = jtype
	FROM @CurrPaths
	WHERE jtype IN (4, 5)
	
	IF @@ROWCOUNT = 0 BREAK;
	
	IF @Verbose = 1 RAISERROR(N'Analysing path "%s"...',0,1,@CurrPath) WITH NOWAIT;

	INSERT INTO @Paths(jpath)
	SELECT @CurrPath + CASE WHEN @CurrType = 5 THEN N'.' + [Key] ELSE QUOTENAME([Key]) END
	FROM OPENJSON(@JDoc, @CurrPath)
	WHERE [Key] = @jElementToFind

	IF @@ROWCOUNT > 0 AND @Verbose = 1 RAISERROR(N'!!! === FOUND element "%s" under path "%s" === !!!',0,1,@jElementToFind,@CurrPath) WITH NOWAIT;

	DELETE FROM @CurrPaths
	WHERE jtype IN (4, 5) AND @CurrPath = jpath

	INSERT INTO @CurrPaths (jkey, jvalue, jtype, jpath)
	SELECT [Key], Value, Type, @CurrPath + CASE WHEN @CurrType = 5 THEN N'.' + [Key] ELSE QUOTENAME([Key]) END
	FROM OPENJSON(@JDoc, @CurrPath)
	WHERE [Type] IN (4, 5);

	IF @Verbose = 1 RAISERROR(N'Got %d more path(s) under "%s"',0,1,@@ROWCOUNT, @CurrPath) WITH NOWAIT;

	SET @CurrPath = NULL;
END

--IF @Verbose = 1 SELECT * FROM @Paths

SELECT @JDoc = JSON_MODIFY(@JDoc, jpath, @jReplacementValue)
FROM @Paths

RAISERROR(N'Replaced element "%s" in %d path(s)',0,1, @jElementToFind,@@ROWCOUNT) WITH NOWAIT;
GO