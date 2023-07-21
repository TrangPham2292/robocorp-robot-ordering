*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Smartsheet
Library    RPA.Tables
Library    Collections
Library    RPA.PDF
Library    OperatingSystem
Library    RPA.Archive

*** Variables ***
${CSV_DOWNLOAD_PATH}=    ${OUTPUT_DIR}${/}orders.csv
${FPD_FILES_TEMP_DIRECTORY}=    ${CURDIR}${/}temp
${GLOBAL_RETRY_AMOUNT}=    5x
${GLOBAL_RETRY_INTERVAL}=    0.5s

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Go to the order website
    Process orders
    Creat ZIP for PDF files

*** Keywords ***
Go to the order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the popup
    ${isPopUpVisible}=    Is Element Visible    css:div.modal
    ${consentPopUpContent}=    Execute Javascript    return document.querySelector("div.modal-body p").innerHTML
    IF    "${consentPopUpContent}" in "By using this order form, I give up all my constitutional rights for the benefit of RobotSpareBin Industries Inc." and ${isPopUpVisible} == ${True}
        Click Button    OK
    END

Get orders
    ${ordersCSV}=    Download    https://robotsparebinindustries.com/orders.csv    ${CSV_DOWNLOAD_PATH}    overwrite=${True}
    ${ordersTable}=    Read table from CSV    ${CSV_DOWNLOAD_PATH}    header=${True} 
    RETURN    ${ordersTable}

Process orders
    ${ordersTable}=    Get orders
    FOR    ${orderItem}    IN    @{ordersTable}
        Wait Until Keyword Succeeds    
        ...    ${GLOBAL_RETRY_AMOUNT}    
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Process single order    ${orderItem}
    END

Process single order
    [Arguments]    ${orderItem}
    Close the popup
    Fill in form for an order    ${orderItem}
    Preview the bot
    Submit the order
    Store the order receipt as PDF file    ${orderItem}[Order number]
    Click Button    Order another robot

Fill in form for an order
    [Arguments]    ${orderItem}
    Log    Fill form for an order ${orderItem}
    Log    ${orderItem}[Head]
    Select From List By Value    id:head    ${orderItem}[Head]
    Select Radio Button    body    ${orderItem}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${orderItem}[Legs]
    Input Text    address    ${orderItem}[Address]

Preview the bot
    Click Button    Preview

Submit the order
    Click Button    Order

Store the order receipt as PDF file
    [Arguments]    ${orderId}
    Wait Until Element Is Visible    id:receipt
    Screenshot    robot-preview-image    ${FPD_FILES_TEMP_DIRECTORY}${/}robot-preview-image-${orderId}.png
    ${receiptHTML}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receiptHTML}    ${FPD_FILES_TEMP_DIRECTORY}${/}order-${orderId}.pdf
    Add Watermark Image To Pdf    ${FPD_FILES_TEMP_DIRECTORY}${/}robot-preview-image-${orderId}.png    ${FPD_FILES_TEMP_DIRECTORY}${/}order-${orderId}.pdf    ${FPD_FILES_TEMP_DIRECTORY}${/}order-${orderId}.pdf
    Remove File    ${FPD_FILES_TEMP_DIRECTORY}${/}robot-preview-image-${orderId}.png

Creat ZIP for PDF files
    Archive Folder With Zip     ${FPD_FILES_TEMP_DIRECTORY}    ${OUTPUT_DIR}${/}Orders.zip
    Remove Directory    ${FPD_FILES_TEMP_DIRECTORY}    ${True}