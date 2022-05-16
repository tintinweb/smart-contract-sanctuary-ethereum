// SPDX-License-Identifier: UNLICENSED
/// @title PonziRugs
/// @notice PonziRugs Mock
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.13;

// To test in testnets
contract PonziRugs {
    address maker;
    constructor() {
        maker = msg.sender;
    }

    function tokenURI(uint256) external pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjogIlBvbnppIFJ1Z3MgIzEiLCAiZGVzY3JpcHRpb24iOiAiRXZlciBiZWVuIHJ1Z2dlZCBiZWZvcmU/IEdvb2QsIE5vdyB5b3UgY2FuIGRvIGl0IG9uIGNoYWluISBObyBJUEZTLCBubyBBUEksIGFsbCBpbWFnZXMgYW5kIG1ldGFkYXRhIGV4aXN0IG9uIHRoZSBibG9ja2NoYWluLiIsImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QmpkWE4wYjIxUVlYUjBaWEp1SUQwZ0lqVWlJSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SWdjSEpsYzJWeWRtVkJjM0JsWTNSU1lYUnBiejBpZUUxcGJsbE5hVzRnYldWbGRDSWdkbWxsZDBKdmVEMGlNQ0F3SURFeU9DQTFOU0lnUGp4d1lYUjBaWEp1SUdsa1BTSnRiMjl1SWlCMmFXVjNRbTk0UFNJd0xDMHdMalVzTVRBc01UQWlJSGRwWkhSb1BTSXhNREFsSWlCb1pXbG5hSFE5SWpFd01DVWlQanh5WldOMElIZHBaSFJvUFNJeE1DSWdhR1ZwWjJoMFBTSXhNQ0lnWm1sc2JEMGlZM0pwYlhOdmJpSWdjM1J5YjJ0bFBTSmliR0ZqYXlJZ2MzUnliMnRsTFhkcFpIUm9QU0l5SWlCMGNtRnVjMlp2Y20wOUluUnlZVzV6YkdGMFpTZ3dMakExTEMwd0xqVXBJaTgrUEhKbFkzUWdkMmxrZEdnOUlqVWlJR2hsYVdkb2REMGlOU0lnYzNSeWIydGxQU0ppYVhOeGRXVWlJR1pwYkd3OUltTnlhVzF6YjI0aUlIUnlZVzV6Wm05eWJUMGlkSEpoYm5Oc1lYUmxLREl1TlN3eUtTSXZQanh5WldOMElIZHBaSFJvUFNJMElpQm9aV2xuYUhROUlqUWlJSE4wY205clpUMGlZbXhoWTJzaUlHWnBiR3c5SW1OeWFXMXpiMjRpSUhSeVlXNXpabTl5YlQwaWRISmhibk5zWVhSbEtETXNNaTQxS1NJZ2MzUnliMnRsTFhkcFpIUm9QU0l3TGpNaUx6NDhjbVZqZENCM2FXUjBhRDBpTmlJZ2FHVnBaMmgwUFNJMklpQnpkSEp2YTJVOUltSnNZV05ySWlCbWFXeHNQU0p1YjI1bElpQjBjbUZ1YzJadmNtMDlJblJ5WVc1emJHRjBaU2d5TERFdU5Ta2lJSE4wY205clpTMTNhV1IwYUQwaU1DNHpJaTgrUEdOcGNtTnNaU0JqZUQwaU5TSWdZM2s5SWpRdU5TSWdjajBpTVNJZ2MzUnliMnRsUFNKaWFYTnhkV1VpSUdacGJHdzlJbVJoY210MGRYSnhkVzlwYzJVaUx6NDhaeUJ6ZEhKdmEyVTlJbUpzWVdOcklpQnpkSEp2YTJVdGQybGtkR2c5SWpBdU15SWdabWxzYkQwaWJtOXVaU0krUEdOcGNtTnNaU0JqZUQwaU5TSWdZM2s5SWpRdU5TSWdjajBpTVM0MUlpOCtQR05wY21Oc1pTQmplRDBpTlNJZ1kzazlJalF1TlNJZ2NqMGlNQzQxSWk4K0lEd3ZaejQ4TDNCaGRIUmxjbTQrUEhCaGRIUmxjbTRnYVdROUluTjBZWElpSUhacFpYZENiM2c5SWpjc0xUQXVOU3czTERFd0lpQjNhV1IwYUQwaU1UY2xJaUJvWldsbmFIUTlJakl3SlNJK1BHY2dabWxzYkQwaWRYSnNLQ050YjI5dUtTSWdjM1J5YjJ0bFBTSmtZWEpyZEhWeWNYVnZhWE5sSWo0OGNtVmpkQ0IzYVdSMGFEMGlNVEFpSUdobGFXZG9kRDBpTVRBaUlIUnlZVzV6Wm05eWJUMGlkSEpoYm5Oc1lYUmxLREFzTFRBdU5Ta2lMejQ4Y21WamRDQjNhV1IwYUQwaU1UQWlJR2hsYVdkb2REMGlNVEFpSUhSeVlXNXpabTl5YlQwaWRISmhibk5zWVhSbEtERXdMRFF1TlNraUx6NDhjbVZqZENCM2FXUjBhRDBpTVRBaUlHaGxhV2RvZEQwaU1UQWlJSFJ5WVc1elptOXliVDBpZEhKaGJuTnNZWFJsS0RFd0xDMDFMalVwSWk4K1BDOW5QanhoYm1sdFlYUmxJR0YwZEhKcFluVjBaVTVoYldVOUluZ2lJR1p5YjIwOUlqQWlJSFJ2UFNJd0xqRTNJaUJrZFhJOUlqRXVORE56SWlCeVpYQmxZWFJEYjNWdWREMGlhVzVrWldacGJtbDBaU0l2UGp3dmNHRjBkR1Z5Ymo0OGNtVmpkQ0IzYVdSMGFEMGlNVEk0SWlCb1pXbG5hSFE5SWpVMUlpQm1hV3hzUFNKMWNtd29JM04wWVhJcElpQnpkSEp2YTJVdGQybGtkR2c5SWpNaUlITjBjbTlyWlQwaVlteGhZMnNpTHo0OEwzTjJaejQ9IiwiYXR0cmlidXRlcyI6IFt7InRyYWl0X3R5cGUiOiAiUGF0dGVybiIsInZhbHVlIjoiUGVyc2lhbiJ9LHsidHJhaXRfdHlwZSI6ICJCYWNrZ3JvdW5kIiwidmFsdWUiOiJkYXJrdHVycXVvaXNlIn0seyJ0cmFpdF90eXBlIjogIkNvbG9yIE9uZSIsInZhbHVlIjogImNyaW1zb24ifSx7InRyYWl0X3R5cGUiOiAiQ29sb3IgVHdvIiwidmFsdWUiOiAiYmlzcXVlIn0seyJ0cmFpdF90eXBlIjogIkNvbG9yIFRocmVlIiwidmFsdWUiOiAiZGFya3R1cnF1b2lzZSJ9XX0=";
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return tokenId % 5 == 0 ? maker : address(this);
    }

}