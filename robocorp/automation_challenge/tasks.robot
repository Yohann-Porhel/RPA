*** Settings ***
Documentation       Open Excel File.
...                 Open the Automation Challenge website.
...                 Connection.
...                 Start The Challenge.
...                 Get The EIN Input Xpath Index.
...                 Fill The Form.
...                 Submit The Form.

Library     RPA.Browser.Selenium
Library     RPA.Excel.Files
Library     RPA.Tables


*** Variables ***
&{fields}=
...     Company Name=company_name
...     Sector=sector
...     Address=company_address
...     Automation Tool=automation_tool
...     Annual Saving=annual_automation_saving
...     Date=date_of_first_project


*** Keywords ***
Connection
    Click Element When Visible                      //button[text()="SIGN UP OR LOGIN"]
    Click Element When Visible                      //button[text()="OR LOGIN"]
    Wait Until Element Is Enabled                   //input[@type="email"]
    Input Text      //input[@type="email"]          yohann.porhel@laposte.net
    Wait Until Element Is Enabled                   //input[@type="password"]
    Input Text      //input[@type="password"]       Valentikiki69$
    Click Element When Visible                      //button[text()="LOG IN"]

Get The EIN Input Xpath Index
    [Arguments]     ${row}
    
    Wait Until Page Contains    EIN
    Wait Until Page Contains    Submit
    ${count}=       Get Element Count       //div[text()="EIN"]/ancestor::div[@class="bubble-element Group"][1]/descendant::input

    FOR     ${i}    IN RANGE    ${count}
        ${result}       ${message}=     Run Keyword And Ignore Error    Input Text      (//div[text()="EIN"]/ancestor::div[@class="bubble-element Group"][1]/descendant::input)[${count}]       ${row}[employer_identification_number]
        IF      "${result}"=="PASS"     Run Keywords    Set Test Variable       ${xpath_index}      ${count}    AND     Exit For Loop
        ${count}=       Evaluate    ${count}-1
    END

Fill The Form
    [Arguments]     ${row}

    FOR     ${key}      ${value}    IN      &{fields}
        Input Text      (//div[text()="${key}"]/ancestor::div[@class="bubble-element Group"][1]/descendant::input)[${xpath_index}]      ${row}[${value}]
    END

Open Excel File
    Open Workbook       ${CURDIR}${/}challenge.xlsx
    ${worksheet}=       Read worksheet      header=${TRUE}
    ${datas}=           Create table        ${worksheet}
    [Return]            ${datas}
    [Teardown]          Close workbook

Open The Automation Challenge Website
    Open Headless Chrome Browser    https://www.theautomationchallenge.com/
    Maximize Browser Window

Start The Challenge
    Sleep       2s
    Click Element When Visible      //button[text()="Start"]
    Sleep       100ms

Submit The Form
    ${count}=       Get Element Count       //button[text()="Submit"]
    ${captcha_visible}=     Run Keyword And Return Status       Element Should Be Visible       //button[text()="presentation"]
    IF      ${captcha_visible}      Run Keywords    Click Button    //button[text()="presentation"]     AND     Wait Until Element Is Visible       //button[text()="presentation"]

    FOR     ${i}    IN RANGE    1       ${count+1}
        ${result}       ${message}=     Run Keyword And Ignore Error    Click Button    (//button[text()="Submit"])[${i}]
        Exit For Loop If    "${result}"=="PASS"
    END


*** Tasks ***
Automation Challenge
    ${datas}=       Open Excel File
    Open The Automation Challenge Website
    Connection
    Start The Challenge
    FOR     ${row}      IN      @{datas}
        Get The EIN Input Xpath Index       ${row}
        Fill The Form                       ${row}
        Submit The Form
    END
