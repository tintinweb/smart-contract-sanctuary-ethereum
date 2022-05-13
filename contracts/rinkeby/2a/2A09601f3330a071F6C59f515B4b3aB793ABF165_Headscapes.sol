// SPDX-License-Identifier: UNLICENSED
/// @title Headscapes
/// @notice Headscapes Mock
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
contract Headscapes {
    address maker;
    constructor() {
        maker = msg.sender;
    }

    function tokenURI(uint256) external pure returns (string memory) {
        return "data:application/json;base64,eyJuYW1lIjogIkhlYWRzY2FwZSAjMTMiLCAiYXR0cmlidXRlcyI6IFt7InRyYWl0X3R5cGUiOiAiQmx1ciIsInZhbHVlIjogIk5vbmUifSx7InRyYWl0X3R5cGUiOiAiR3JhZGllbnQiLCJ2YWx1ZSI6ICJOb25lIn0seyJ0cmFpdF90eXBlIjogIkxpZ2h0IiwidmFsdWUiOiAiTm9uZSJ9LHsidHJhaXRfdHlwZSI6ICJEaXNwbGFjZW1lbnQgTWFwIiwidmFsdWUiOiAiMjAifSx7InRyYWl0X3R5cGUiOiAiUGFsZXR0ZSIsInZhbHVlIjogIkF1dHVtbiBDcnVzaCJ9LHsidHJhaXRfdHlwZSI6ICJQYXR0ZXJuIiwidmFsdWUiOiAiRG90cyAmIExpbmVzIn0seyJ0cmFpdF90eXBlIjogIlR1cmJ1bGVuY2UiLCJ2YWx1ZSI6ICJUdXJidWxlbmNlIDEifSx7InRyYWl0X3R5cGUiOiAiVGl0bGVkIiwidmFsdWUiOiAiZmFsc2UifV0sICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlNVFV3TUNJZ2FHVnBaMmgwUFNJMU1EQWlJSFpsY25OcGIyNDlJakV1TVNJZ2VHMXNibk05SW1oMGRIQTZMeTkzZDNjdWR6TXViM0puTHpJd01EQXZjM1puSWlCemRIbHNaVDBpY0c5emFYUnBiMjQ2SUhKbGJHRjBhWFpsT3lCaVlXTnJaM0p2ZFc1a09pQjJZWElvTFMxaUtUc2lJR05zWVhOelBTSmpNQ0krUEhOMGVXeGxQaTVqTUhzdExXSTZJQ05GTVVFeE5EQTdJQzB0Y3pvZ0l6VXpNakl3TURzZ0xTMWhPaUFqUlVaRFJrRXdPeUF0TFcwNklDTTVNVFF4TVRBN2ZUd3ZjM1I1YkdVK1BHUmxabk0rUEhCaGRIUmxjbTRnYVdROUluQXdJaUI0UFNJeE1pSWdlVDBpTFRVaUlIZHBaSFJvUFNJek56VWlJR2hsYVdkb2REMGlOakl1TlNJZ2NHRjBkR1Z5YmxWdWFYUnpQU0oxYzJWeVUzQmhZMlZQYmxWelpTSStQR3hwYm1WaGNrZHlZV1JwWlc1MElHbGtQU0puTVNJK1BITjBiM0FnYjJabWMyVjBQU0kxSlNJZ2MzUnZjQzFqYjJ4dmNqMGlkbUZ5S0MwdGN5a2lMejQ4YzNSdmNDQnZabVp6WlhROUlqVXdKU0lnYzNSdmNDMWpiMnh2Y2owaWRtRnlLQzB0YlNraUx6NDhjM1J2Y0NCdlptWnpaWFE5SWprMUpTSWdjM1J2Y0MxamIyeHZjajBpZG1GeUtDMHRjeWtpTHo0OEwyeHBibVZoY2tkeVlXUnBaVzUwUGp4eVlXUnBZV3hIY21Ga2FXVnVkQ0JwWkQwaVp6SWlQanh6ZEc5d0lHOW1abk5sZEQwaU1UQWxJaUJ6ZEc5d0xXTnZiRzl5UFNKMllYSW9MUzF6S1NJdlBqeHpkRzl3SUc5bVpuTmxkRDBpTlRBbElpQnpkRzl3TFdOdmJHOXlQU0oyWVhJb0xTMWhLU0l2UGp3dmNtRmthV0ZzUjNKaFpHbGxiblErUEhKbFkzUWdabWxzYkQwaWRYSnNLQ05uTVNraUlHaGxhV2RvZEQwaU1UQWlJSGRwWkhSb1BTSXpOelVpSUhnOUlqQWlJSGs5SWpBaUx6NDhaeUJtYVd4c0xXOXdZV05wZEhrOUlqQXVOU0lnYzNSeWIydGxQU0oyWVhJb0xTMXpLU0lnWm1sc2JEMGlkWEpzS0NObk1pa2lQanhqYVhKamJHVWdZM2c5SWpJd0lpQmplVDBpTkRBaUlISTlJalVpSUhOMGNtOXJaUzEzYVdSMGFEMGlNU0l2UGp4amFYSmpiR1VnWTNnOUlqZ3lMalVpSUdONVBTSTBNQ0lnY2owaU55SWdjM1J5YjJ0bExYZHBaSFJvUFNJeklpQXZQanhqYVhKamJHVWdZM2c5SWpFME5TSWdZM2s5SWpRd0lpQnlQU0kwSWlCemRISnZhMlV0ZDJsa2RHZzlJak1pTHo0OFkybHlZMnhsSUdONFBTSXlNRGN1TlNJZ1kzazlJalF3SWlCeVBTSTRJaUJ6ZEhKdmEyVXRkMmxrZEdnOUlqSWlMejQ4WTJseVkyeGxJR040UFNJeU56QWlJR041UFNJME1DSWdjajBpTWlJZ2MzUnliMnRsTFhkcFpIUm9QU0l6SWk4K1BHTnBjbU5zWlNCamVEMGlNek15TGpVaUlHTjVQU0kwTUNJZ2NqMGlNeTQxSWlCemRISnZhMlV0ZDJsa2RHZzlJakVpTHo0OEwyYytQQzl3WVhSMFpYSnVQanhtYVd4MFpYSWdhV1E5SW1Zd0lqNDhabVZVZFhKaWRXeGxibU5sSUhSNWNHVTlJblIxY21KMWJHVnVZMlVpSUdKaGMyVkdjbVZ4ZFdWdVkzazlJakF1TURrc0lDNHdOaUlnYm5WdFQyTjBZWFpsY3owaU1TSWdjMlZsWkQwaU1UTWlJSEpsYzNWc2REMGljakVpSUM4K1BHWmxSR2x6Y0d4aFkyVnRaVzUwVFdGd0lHbHVNajBpY2pFaUlISmxjM1ZzZEQwaWNqSWlJR2x1UFNKVGIzVnlZMlZIY21Gd2FHbGpJaUJ6WTJGc1pUMGlNakFpSUhoRGFHRnVibVZzVTJWc1pXTjBiM0k5SWxJaUlIbERhR0Z1Ym1Wc1UyVnNaV04wYjNJOUlrSWlJQzgrUEdabFIyRjFjM05wWVc1Q2JIVnlJSE4wWkVSbGRtbGhkR2x2YmowaU1DNHdJaUJwYmowaWNqSWlJSEpsYzNWc2REMGljak1pSUM4K1BHWmxUV1Z5WjJVK1BHWmxUV1Z5WjJWT2IyUmxJR2x1UFNKeU5DSWdMejQ4Wm1WTlpYSm5aVTV2WkdVZ2FXNDlJbkl5SWlBdlBqd3ZabVZOWlhKblpUNDhMMlpwYkhSbGNqNDhMMlJsWm5NK1BISmxZM1FnYUdWcFoyaDBQU0kxTURBaUlIZHBaSFJvUFNJeE5UQXdJaUJtYVd4MFpYSTlJblZ5YkNnalpqQXBJaUJtYVd4c1BTSjFjbXdvSTNBd0tTSWdMejQ4TDNOMlp6ND0ifQ==";
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return tokenId % 5 == 0 ? maker : address(this);
    }

}