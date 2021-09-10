*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Archive
Library             RPA.Browser.Selenium
Library             RPA.Dialogs
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Robocloud.Secrets


*** Keywords ***
Close the annoying modal
    ${res}=     Run Keyword And Return Status       Element Should Be Visible       //button[@class="btn btn-dark"]
    Run Keyword If      ${res}                      Click Button                    //button[@class="btn btn-dark"]

Close the browser
    Close Browser

Create a ZIP file of the receipts
    Archive Folder With Zip     ${OUTPUT_DIR}${/}receipts       receipts.zip

Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}       ${pdf}

    Open Pdf        ${pdf}
    Add Watermark Image To PDF
    ...             image_path=${screenshot}
    ...             source_path=${pdf}
    ...             output_path=${pdf}
    Close Pdf       ${pdf}

Fill the form
    [Arguments]     ${row}

    Select From List By Value       head                                                        ${row}[Head]
    Select Radio Button             body                                                        ${row}[Body]
    Input Text                      //*[@placeholder="Enter the part number for the legs"]      ${row}[Legs]
    Input Text                      address                                                     ${row}[Address]

Get orders
    Add heading         Provide the URL of the orders CSV file
    Add text input      URL     label=URL
    ${result}=          Run dialog

    Download        ${result.URL}       overwrite=True
    ${orders}=      Read table from CSV     orders.csv      header=True

    [Return]        ${orders}

Go to order another robot
    Click Button    order-another

Open the robot order website
    ${secret}=      Get Secret      website
    Open Available Browser          ${secret}[url]
    Maximize Browser Window
    Click Button When Visible       //button[@class="btn btn-dark"]

Preview the robot
    Click Button    preview

Store the receipt as a PDF file
    [Arguments]     ${orderNumber}

    ${receipt}=     Get Element Attribute       id:receipt      outerHTML
    Html To Pdf     ${receipt}      ${OUTPUT_DIR}${/}receipts${/}Order N°${orderNumber}.pdf
    ${pdf}=     Set Variable        ${OUTPUT_DIR}${/}receipts${/}Order N°${orderNumber}.pdf

    [Return]    ${pdf}

Submit the order
    Click Button    order
    Wait Until Element Is Visible       order-another       timeout=1s

Take a screenshot of the robot
    [Arguments]     ${orderNumber}

    Screenshot          id:robot-preview-image      ${OUTPUT_DIR}${/}screenshot.png
    ${screenshot}=      Set Variable                ${OUTPUT_DIR}${/}screenshot.png

    [Return]    ${screenshot}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=      Get orders
    FOR     ${row}      IN      @{orders}
            Close the annoying modal
            Fill the form       ${row}
            Preview the robot
            Wait Until Keyword Succeeds     5x      0.5s    Submit the order
            ${pdf}=             Store the receipt as a PDF file     ${row}[Order number]
            ${screenshot}=      Take a screenshot of the robot      ${row}[Order number]
            Embed the robot screenshot to the receipt PDF file      ${screenshot}       ${pdf}
            Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]      Close the browser
