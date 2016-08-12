*** Settings ***

Documentation  Common keywords for OpenERP tests
...            versions of the application. The correct SUT specific resource
...            is imported based on ${SUT} variable. SeleniumLibrary is also
...            imported here so that no other file needs to import it.
Library     Selenium2Library
Library     String
Library     pabot.PabotLib
Library     DateTime
Library     ImapLibrary
Library     re
Library     Collections
Library     XvfbRobot
Variables   ${CONFIG}


*** Keywords ***

# Login
Open New Browser    [Arguments]     ${url}
    Run Keyword If    '${HEADLESS}' == 'yes'     Start Virtual Display    1920       1680
    Open Browser       ${url}                    ${BROWSER}               ${ALIAS}
    Run Keyword If    '${HEADLESS}' == 'yes'     Set Window Size          1920       1680

Login    [Arguments]    ${url}=${ODOO_URL_LOGIN}    ${user}=${ODOO_USER}    ${password}=${ODOO_PASSWORD}    ${db}=${ODOO_DB}    ${bamboo}=${BAMBOO}
    Open New Browser                    ${url}
    Maximize Browser Window
    Go To                               ${url}
    Set Selenium Speed                  ${SELENIUM_DELAY}
    Set Selenium Timeout                ${SELENIUM_TIMEOUT}
    Run Keyword If                      '${bamboo}' != 'yes'      Wait Until Page Contains Element    xpath=//select[@id='db']
    Run Keyword If                      '${bamboo}' != 'yes'      Select From List By Value           xpath=//select[@id='db']    ${db}
    Wait Until Page Contains Element    name=login
    Input Text                          name=login  ${user}
    Input Password                      name=password   ${password}
    Click Button                        xpath=//div[contains(@class,'oe_login_buttons')]/button[@type='submit']
    Wait Until Page Contains Element    xpath=//div[@id='oe_main_menu_placeholder']/ul/li/a/span
    Wait For Ajax                       1

OnFailure
    Release Value Set
    Capture Page Screenshot

LoginLockUser    [Arguments]    ${url}=${ODOO_URL_LOGIN}    ${db}=${ODOO_DB}    ${bamboo}=${BAMBOO}
    Register Keyword To Run On Failure    OnFailure
    ${users}=            Acquire Value Set
    ${user}=             Get Value From Set    username
    ${password}=         Get Value From Set    password
    Login       ${url}    ${user}    ${password}    ${db}    ${bamboo}

UnlockUser
   Release Value Set


# Database
DatabaseConnect    [Arguments]    ${odoo_db}=${ODOO_DB}    ${odoo_db_user}=${ODOO_DB_USER}    ${odoo_db_password}=${ODOO_DB_PASSWORD}    ${odoo_db_server}=${SERVER}    ${odoo_db_port}=${ODOO_DB_PORT}
    Connect To Database Using Custom Params	psycopg2        database='${odoo_db}',user='${odoo_db_user}',password='${odoo_db_password}',host='${odoo_db_server}',port=${odoo_db_port}

DatabaseDisconnect
    Disconnect from Database


# Menu
MainMenu    [Arguments]    ${menu}
    Wait Until Element Is Visible       xpath=//div[@id='oe_main_menu_placeholder']/ul/li/a[descendant::span/text()[normalize-space()='${menu}']]    ${SELENIUM_TIMEOUT}
    ${main_menu_id}=                    Execute JavaScript    return $("div#oe_main_menu_placeholder ul li a:contains('${menu}')").data('menu')
    Click Element                       xpath=//div[@id='oe_main_menu_placeholder']/ul/li/a[descendant::span/text()[normalize-space()='${menu}']]
    Wait Until Element Is Visible       jquery=div.oe_secondary_menus_container:visible div.oe_secondary_menu[data-menu-parent='${main_menu_id}']:visible
    ElementPostCheck

SubMenu    [Arguments]    ${menu}
    Wait Until Element Is Visible       xpath=//div[contains(@class, 'oe_secondary_menus_container')]/div[contains(@class, 'oe_secondary_menu') and not(contains(@style, 'display: none'))]/ul/li/a[descendant::span/text()[normalize-space()='${menu}']]    ${SELENIUM_TIMEOUT}
    Click Link                          xpath=//div[contains(@class, 'oe_secondary_menus_container')]/div[contains(@class, 'oe_secondary_menu') and not(contains(@style, 'display: none'))]/ul/li/a[descendant::span/text()[normalize-space()='${menu}']]
    Wait Until Page Contains Element    xpath=//div[contains(@class,'oe_view_manager_current')]
    ElementPostCheck


# Check
Wait For Ajax    [Arguments]     ${active}=0
    ${jqueryactive}=    Execute Javascript    return jQuery.active;
    Wait For Condition    return jQuery.active == '${active}' || jQuery.active == '0';
    ${jqueryactive}=    Execute Javascript    return jQuery.active;

ElementPreCheck    [Arguments]    ${element}
    Execute Javascript      console.log("${element}");
    # Element may be in a tab. So click the parent tab. If there is no parent tab, forget about the result
    Execute Javascript      var path="${element}".replace('xpath=','');var id=document.evaluate("("+path+")/ancestor::div[contains(@class,'oe_notebook_page')]/@id",document,null,XPathResult.STRING_TYPE,null).stringValue; if(id != ''){ window.location = "#"+id; $("a[href='#"+id+"']").click(); console.log("Clicked at #" + id); } return true;

ElementPostCheck
    # Check that page is not loading
    Wait Until Page Contains Element    xpath=//div[contains(@class, 'oe_loading')][contains(@style, 'display: none')]
    # Check that page is not blocked by RPC Call
    Wait Until Page Contains Element    xpath=//body[not(contains(@class, 'oe_wait'))]
    # Check not AJAX request remaining (only longpolling)
    Wait For Ajax    1


# Buttons
Button                      [Arguments]     ${model}    ${button_name}
    Wait Until Page Contains Element    xpath=//div[contains(@class,'openerp')][last()]//*[not(contains(@style,'display:none'))]//button[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${button_name}']
    Wait Until Element Is Visible    xpath=//div[contains(@class,'openerp')][last()]//*[not(contains(@style,'display:none'))]//button[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${button_name}']    ${SELENIUM_TIMEOUT}
    Click Button           xpath=//div[contains(@class,'openerp')][last()]//*[not(contains(@style,'display:none'))]//button[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${button_name}']
    Wait For Condition     return true;    20.0
    ElementPostCheck

KanbanButton                      [Arguments]     ${model}    ${button_name}
    Wait Until Page Contains Element    xpath=//div[contains(@class,'openerp')][last()]//*[not(contains(@style,'display:none'))]//button[@data-bt-testing-button='${button_name}']
    Wait Until Element Is Visible    xpath=//div[contains(@class,'openerp')][last()]//*[not(contains(@style,'display:none'))]//button[@data-bt-testing-button='${button_name}']    ${SELENIUM_TIMEOUT}
    Click Button           xpath=//div[contains(@class,'openerp')][last()]//*[not(contains(@style,'display:none'))]//button[@data-bt-testing-button='${button_name}']
    Wait For Condition     return true;    20.0
    ElementPostCheck

UploadFile    [Arguments]    ${model}    ${field}    ${path}
    ElementPreCheck    xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Choose File    xpath=//div[contains(@class,'openerp')][last()]//table[descendant::input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']]//form[contains(@class, 'oe_form_binary_form')]//input[@name='ufile']    ${path}
    ElementPostCheck


# Fields -> Common
WriteInField                [Arguments]     ${model}    ${fieldname}    ${value}
    ElementPreCheck         xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${fieldname}']|textarea[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${fieldname}']
    Input Text              xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${fieldname}']|textarea[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${fieldname}']    ${value}
    ElementPostCheck

Date    [Arguments]    ${model}    ${field}    ${value}
    ElementPreCheck        xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Input Text             xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']    ${value}
    ElementPostCheck

Char    [Arguments]    ${model}    ${field}    ${value}
    ElementPreCheck        xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Execute Javascript     $("div.openerp:last input[data-bt-testing-model_name='${model}'][data-bt-testing-name='${field}']").val(''); return true;
    Input Text             xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']    ${value}
    ElementPostCheck

Float    [Arguments]    ${model}    ${field}    ${value}
    ElementPreCheck        xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Input Text             xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']    ${value}
    ElementPostCheck

Text    [Arguments]    ${model}    ${field}    ${value}
    ElementPreCheck        xpath=//div[contains(@class,'openerp')][last()]//textarea[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Input Text             xpath=//div[contains(@class,'openerp')][last()]//textarea[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']    ${value}
    ElementPostCheck

Select-Option    [Arguments]    ${model}    ${field}    ${value}
    ElementPreCheck        xpath=//div[contains(@class,'openerp')][last()]//select[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Select From List By Label	xpath=//div[contains(@class,'openerp')][last()]//select[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']    ${value}
    ElementPostCheck

Checkbox    [Arguments]    ${model}    ${field}
    ElementPreCheck        xpath=//div[contains(@class,'openerp')][last()]//input[@type='checkbox' and @data-bt-testing-name='${field}' and @data-bt-testing-model_name='${model}']
    Checkbox Should Not Be Selected    xpath=//div[contains(@class,'openerp')][last()]//input[@type='checkbox' and @data-bt-testing-name='${field}' and @data-bt-testing-model_name='${model}']
    Click Element          xpath=//div[contains(@class,'openerp')][last()]//input[@type='checkbox' and @data-bt-testing-name='${field}' and @data-bt-testing-model_name='${model}']
    ElementPostCheck

NotCheckbox    [Arguments]    ${model}    ${field}
    ElementPreCheck        xpath=//div[contains(@class,'openerp')][last()]//input[@type='checkbox' and @data-bt-testing-name='${field}' and @data-bt-testing-model_name='${model}']
    Checkbox Should Be Selected    xpath=//div[contains(@class,'openerp')][last()]//input[@type='checkbox' and @data-bt-testing-name='${field}' and @data-bt-testing-model_name='${model}']
    Click Element          xpath=//div[contains(@class,'openerp')][last()]//input[@type='checkbox' and @data-bt-testing-name='${field}' and @data-bt-testing-model_name='${model}']
    ElementPostCheck

Radio    [Arguments]    ${model}    ${field}
    ElementPreCheck        xpath=//div[contains(@class,'openerp')][last()]//input[@type='radio' and @data-bt-testing-name='${field}' and @data-bt-testing-model_name='${model}']
    ${path}=               Execute JavaScript    return $('ul[role=tablist] li a:visible:contains("Kontakt Informationen")').attr('href').replace('#', '');
    Click Element          xpath=//div[contains(@class,'openerp')][last()]//input[@type='radio' and @name='${path}_${model}_${field}']
    ElementPostCheck


# Fields -> Many2One
Many2OneSelect    [Arguments]    ${model}    ${field}    ${value}
    ElementPreCheck     xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Input Text          xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']    ${value}
    Wait Until Page Contains Element    xpath=//ul[contains(@class,'ui-autocomplete') and not(contains(@style,'display: none'))]/li[1]/a[contains(text(), '${value}')]
    Click Link             xpath=//ul[contains(@class,'ui-autocomplete') and not(contains(@style,'display: none'))]/li[1]/a[contains(text(), '${value}')]
    Textfield Should Contain    xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']    ${value}
    ElementPostCheck

Many2OneCreateAndEdit    [Arguments]    ${model}    ${field}    ${value}
    ElementPreCheck     xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Input Text          xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']    ${value}
    Wait Until Page Contains Element    xpath=//ul[contains(@class,'ui-autocomplete') and not(contains(@style,'display: none'))]/li[1]/a[contains(text(), 'Anlegen und Bearbeiten')]
    Click Link             xpath=//ul[contains(@class,'ui-autocomplete') and not(contains(@style,'display: none'))]/li[1]/a[contains(text(), 'Anlegen und Bearbeiten')]
    Wait Until Element Is Visible     jquery=div.modal-dialog div.modal-header h3.modal-title:contains('Anlegen')
    ElementPostCheck

ClearMany2OneSelect    [Arguments]    ${model}    ${field}
    ElementPreCheck    xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Clear Element Text    xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']
    Press Key    xpath=//div[contains(@class,'openerp')][last()]//input[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']    \\13
    ElementPostCheck


# Fields -> One2Many
NewOne2Many    [Arguments]    ${model}    ${field}
    ElementPreCheck        xpath=//div[contains(@class,'openerp')][last()]//div[contains(@class,'oe_form_field_one2many')]//div[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']//tr/td[contains(@class,'oe_form_field_one2many_list_row_add')]/a
    Click Link             xpath=//div[contains(@class,'openerp')][last()]//div[contains(@class,'oe_form_field_one2many')]//div[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']//tr/td[contains(@class,'oe_form_field_one2many_list_row_add')]/a
    ElementPostCheck

One2ManySelectRecord  [Arguments]    ${model}    ${field}    ${submodel}    @{fields}
    ElementPreCheck    xpath=//div[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']

    # Initialize variable
    ${pre_check_xpath}=    Set Variable
    ${post_check_xpath}=    Set Variable
    ${pre_click_xpath}=    Set Variable
    ${post_click_xpath}=    Set Variable
    ${pre_check_xpath}=    Catenate    (//div[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']//table[contains(@class,'oe_list_content')]//tr[descendant::td[
    ${post_check_xpath}=    Catenate    ]])[1]
    ${pre_click_xpath}=    Catenate    (//div[@data-bt-testing-model_name='${model}' and @data-bt-testing-name='${field}']//table[contains(@class,'oe_list_content')]//tr[
    ${post_click_xpath}=    Catenate    ]/td)[1]
    ${xpath}=    Set Variable

    # Got throught all field=value and to select the correct record
    : FOR    ${field}    IN  @{fields}
    # Split the string in fieldname=fieldvalue
    \    ${fieldname}    ${fieldvalue}=    Split String    ${field}    separator==    max_split=1
    \    ${fieldxpath}=    Catenate    @data-bt-testing-model_name='${submodel}' and @data-field='${fieldname}'

         # We first check if this field is in the view and visible
         # otherwise a single field can break the whole command

    \    ${checkxpath}=     Catenate    ${pre_check_xpath} ${fieldxpath} ${post_check_xpath}
    \    Log To Console    ${checkxpath}
    \    ${status}    ${value}=    Run Keyword And Ignore Error    Page Should Contain Element    xpath=${checkxpath}

         # In case the field is not there, log a error
    \    Run Keyword Unless     '${status}' == 'PASS'    Log    Field ${fieldname} not in the view or unvisible
         # In case the field is there, add the path to the xpath
    \    ${xpath}=    Set Variable If    '${status}' == 'PASS'    ${xpath} and descendant::td[${fieldxpath} and string()='${fieldvalue}']    ${xpath}

    # remove first " and " again (5 characters)
    ${xpath}=   Get Substring    ${xpath}    5
    ${xpath}=    Catenate    ${pre_click_xpath}    ${xpath}    ${post_click_xpath}
    Click Element    xpath=${xpath}
    ElementPostCheck


# Views
ChangeView    [Arguments]    ${view}
   Click Link                          xpath=//div[contains(@class,'openerp')][last()]//ul[contains(@class,'oe_view_manager_switch')]//a[contains(@data-view-type,'${view}')]
   Wait Until Page Contains Element    xpath=//div[contains(@class,'openerp')][last()]//div[contains(@class,'oe_view_manager_view_${view}') and not(contains(@style, 'display: none'))]
   ElementPostCheck

NotebookPage    [Arguments]    ${value}
    Click Element    xpath=//div[contains(@class,'openerp')][last()]//ul[@role='tablist']//li/a[@data-bt-testing-original-string='${value}']
    ElementPostCheck

SelectListView  [Arguments]    ${model}    @{fields}
    # Initialize variable
    ${xpath}=    Set Variable

    # Got throught all field=value and to select the correct record
    : FOR    ${field}    IN  @{fields}
    # Split the string in fieldname=fieldvalue
    \    ${fieldname}    ${fieldvalue}=    Split String    ${field}    separator==    max_split=1
    \    ${fieldxpath}=    Catenate    @data-bt-testing-model_name='${model}' and @data-field='${fieldname}'

         # We first check if this field is in the view and visible
         # otherwise a single field can break the whole command

    \    ${checkxpath}=     Catenate    (//table[contains(@class,'oe_list_content')]//tr[descendant::td[${fieldxpath}]])[1]
    \    ${status}    ${value}=    Run Keyword And Ignore Error    Page Should Contain Element    xpath=${checkxpath}

         # In case the field is not there, log a error
    \    Run Keyword Unless     '${status}' == 'PASS'    Log    Field ${fieldname} not in the view or unvisible
         # In case the field is there, add the path to the xpath
    \    ${xpath}=    Set Variable If    '${status}' == 'PASS'    ${xpath} and descendant::td[${fieldxpath} and string()='${fieldvalue}']    ${xpath}

    # remove first " and " again (5 characters)
    ${xpath}=   Get Substring    ${xpath}    5
    ${xpath}=    Catenate    (//table[contains(@class,'oe_list_content')]//tr[${xpath}]/td)[1]
    Click Element    xpath=${xpath}
    ElementPostCheck

OpenListViewElement   [Arguments]    ${model}    ${field}    ${value}
    Click Element    xpath=//div[contains(@class,'openerp')][last()]//table[contains(@class, 'oe_list_content')]//td[@data-bt-testing-model_name='${model}' and @data-field='${field}'][contains(text(), '${value}')]
    ElementPostCheck


# Actions
SidebarAction  [Arguments]    ${type}    ${id}
    ClickElement   xpath=//div[contains(@class,'oe_view_manager_sidebar')]/div[not(contains(@style,'display: none'))]//div[contains(@class,'oe_sidebar')]//div[contains(@class,'oe_form_dropdown_section') and descendant::a[@data-bt-type='${type}' and @data-bt-id='${id}']]/button[contains(@class,'oe_dropdown_toggle')]
    ClickLink   xpath=//div[contains(@class,'oe_view_manager_sidebar')]/div[not(contains(@style,'display: none'))]//div[contains(@class,'oe_sidebar')]//a[@data-bt-type='${type}' and @data-bt-id='${id}']
    ElementPostCheck

MainWindowButton            [Arguments]     ${button_text}
    Click Button            xpath=//td[@class='oe_application']//div[contains(@class,'oe_view_manager_current')]//button[contains(text(), '${button_text}')]
    ElementPostCheck

MainWindowNormalField       [Arguments]     ${field}    ${value}
    Input Text              xpath=//td[contains(@class, 'view-manager-main-content')]//input[@name='${field}']  ${value}
    ElementPostCheck

MainWindowSearchTextField   [Arguments]     ${field}    ${value}
    Input Text              xpath=//div[@id='oe_app']//div[contains(@id, '_search')]//input[@name='${field}']   ${value}
    ElementPostCheck

MainWindowSearchNow

MainWindowMany2One          [Arguments]     ${field}    ${value}
    Click Element           xpath=//td[contains(@class, 'view-manager-main-content')]//input[@name='${field}']  don't wait
    Input Text              xpath=//td[contains(@class, 'view-manager-main-content')]//input[@name='${field}']      ${value}
    Click Element           xpath=//td[contains(@class, 'view-manager-main-content')]//input[@name='${field}']/following-sibling::span[contains(@class, 'oe-m2o-drop-down-button')]/img don't wait
    Click Link              xpath=//ul[contains(@class, 'ui-autocomplete') and not(contains(@style, 'display: none'))]//a[self::*/text()='${value}']    don't wait
    ElementPostCheck

