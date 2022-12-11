pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
/*

                                         _«φ≥»_
                                ___       ;░▒[      ____
                           __ _           _▓▓_           _____
                        _           __   _▓▓▓▓_                __
                     _                  ╓▓▓▓▓▓▓╖_   ⁿ _           __
                  _         _       _▄▄▓▓╟▓▀▒▓▓▓▓▄▄__               __
                                     ╓▓█▓██▓▓██▓█▓▄                    _
               _                     _▓██████████▓__                    __
             _                     ,▄▓▓▓▓▓▓▓╬▓▀▓███▓M_     _              _
                      __          ▄▓███▓██▓▓█████▓▓▓▓ç__             _
           _                    └█████╣▓╣██████▒│╟█████─  _                 _
                            __  _▄▓██████████████████▓▄_ _                   _
               _                ___█████████▓█▓██████─_           _           _
         _                       ,▓███▓▓▓▓████████████_          __
                               ▀██████████████████▓████▓▄µ                     _
                      _--     ╓▓█████████▀░███████▓▓█████,_  _          _      _
                       _   "▀████████████▄▄████▓█████▓█████▀^                  _
        _                     ▀█████▓█▓▀█████████████████▀                     _
        _        _           ▄████████████▓▓▓▓████████████▄     ]~
                         "▓█████████▓███████████████▓████████▄  _
         _          ╓▄▄▄▓██▓█▓▓████╬▓█████████████████╬█████████▄▄▄,
         _          _'╙╙▀████▓███▓▓▀███▓█████▀░╠██████▓████████▀╙╙'_
          _            _▓█▀███████████▓███████▓▓█████████████▀▀█_  _
           _     'φ╓φ#_   ╙└└__▀▀▀▓████▀╝▀████▀▌╙▀████▀▀▀__└└╙╓▄_ ╓▄_       _
                 ╟▓▒╬▓▒       _ ,_''_  __j████⌐__ __ _       ╓╠╬╫▓╬╬╓_     _
             __  ╫▓▒╣▓L     ]▄▓▓▓▄⌐  α_▀███▓▓███▀            _▒▒╟▓╬▒╠
              _  ╣▓▒╣▓▌  ,╠▒φ╬▓▓▓╣  ▀▓╬▓▓▓▓▓▓▓▓▓▒▓▓⌐______   ]▒╠║▓╬╠╠_
         ,-»≤≤≤╫▓╣╣▓▓╣▓▓▓▓▓╬╟▓▓▓▓▓,,║▓╬╫▓▓▓▓▓▓▓▓╣▓▓▓▓▓╫╫╫╫╥╓,{▒╠╟▓╬▒╬╓╓▄▄≥≥≤»,,_
       _"=░││││║▓╣▓▓▓▓╣▓▓▓╫▒║╫╫▓▓▌│'▓▓╬╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬▒╬╬▒╠▒╟╣╬╬╬▓╣╬▓▌│││││Γ^
           _ __  `░││││││╚▀▀╝▀▀││││││││││││││░╙╙╙╙╙╙╙╙╙╙╙╙╙╙'││'└└│└└│ _ ____
                  __   ``"""""""ⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿ==ⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿ""""""``   _
*/

import "./ERC721Tradable.sol";

/**
 * @title Xmas
 */
contract Xmas is ERC721Tradable {


    struct NGO {
        address addr;
        string  name;
    }

    struct ICON {
        string name;
        string part_1;
        string part_2;
        string part_3;
        string part_4;
        string part_5;
        uint256 min_donation;
    }

    event new_NGO  (uint256 NGO_id );
    event new_ICON (uint256 icon_id);
    event new_COLOR(uint256 color_id);

    mapping (uint256 => ICON   ) public  ICONs;
    mapping (uint256 => NGO    ) public  NGOs;
    mapping (uint256 => string ) private DONAs;
    mapping (uint256 => string ) public  COLORs;
    uint256 public number_of_NGOs;
    uint256 public number_of_icons;
    uint256 public number_of_colors;

    using SafeMath for uint256;
    using strings for *;

    constructor(address _proxyRegistryAddress) ERC721Tradable("DonateXMas", "XMAS", _proxyRegistryAddress) {

        // REMEMBER: 
        // 1) CHANGE PROXY REGISTRY ADDRESS!!!
        // 2) Remove 0.001

        DONAs[    1000000000000000] = " 0.001";
        DONAs[   50000000000000000] = " 0.05";
        DONAs[  100000000000000000] = " 0.1";
        DONAs[  250000000000000000] = " 0.25";
        DONAs[  500000000000000000] = " 0.5";
        DONAs[ 1000000000000000000] = " 1";
        DONAs[ 5000000000000000000] = " 5";
        DONAs[10000000000000000000] = "10";

        // Icons

            ICONs[1] = ICON("Star 1",
                '<g transform="translate(100 470.37)" fill="',
                '"><circle cx="770.37" cy="29.63" r="29.63"/><circle cx="29.63" cy="29.63" r="29.63"/></g><g transform="translate(470.37 100)" fill="',
                '"><circle cx="29.63" cy="29.63" r="29.63"/><circle cx="29.63" cy="770.37" r="29.63"/></g><path fill="',
                '" d="m499.94 159.2 60.993 193.492 179.948-93.691-93.693 179.947 193.494 60.992-193.493 60.993L740.88 740.88l-179.948-93.692-60.992 193.493-60.993-193.493L259 740.88l93.692-179.948L159.2 499.94l193.492-60.993L259.001 259l179.947 93.692z"/><path fill="',
                '" />',
                1000000000000000
            );

            ICONs[2] = ICON("Mountains",
                '<path fill="',
                '" d="m400 0 400 400H0z" transform="translate(100 100)"/><path fill="',
                '" d="m400 400 400 400H0z" transform="translate(100 100)"/><path d="m400 0 200 200H200L400 0ZM266.666 266.4 200 200h133.334l-66.667 66.4Zm266.668 0L466.667 200h133.334l-66.667 66.4ZM400 266.4 333.334 200h133.332L400 266.4Z" fill="',
                '" transform="translate(100 100)"/><path d="m400 400 200 200H200l200-200ZM266.666 666.4 200 600h133.334l-66.667 66.4Zm266.668 0L466.667 600h133.334l-66.667 66.4ZM400 666.4 333.334 600h133.332L400 666.4Z" fill="',
                '" transform="translate(100 100)"/>',
                1000000000000000
            );

            ICONs[3] = ICON("Tree 1",
                '<g transform="translate(100 100)"><path fill="',
                '" d="m400 0 400 652H0z"/><circle fill="',
                '" cx="399.6" cy="726" r="74"/></g><path fill="',
                '" /><path fill="',
                '" />',
                1000000000000000
            );

            ICONs[4] = ICON("Hat",
                '<g transform="translate(100 100)"><path fill="',
                '" d="m400 148.217 400 503.937H0z"/><ellipse fill="',
                '" cx="400" cy="74.109" rx="74.074" ry="74.109"/><path fill="',
                '" d="M.37 652.525h799.26V800H.37z"/></g><path fill="',
                '"/>',
                1000000000000000
            );

            ICONs[5] = ICON("Tree 2",
                '<g transform="translate(100.000000, 100.000000)"><polygon fill="',
                '" points="400 59.2 800 244 0 244"></polygon><polygon fill="',
                '" points="400 429.6 800 615.2 0 615.2"></polygon><path d="M400,244.8 L800,430.4 L0,430.4 L400,244.8 Z M400,615.2 L800,800 L0,800 L400,615.2 Z" fill="',
                '"></path><circle fill="',
                '" cx="399.2" cy="29.6" r="29.6"></circle></g>',
                1000000000000000
            );

            ICONs[6] = ICON("Snowman",
                '<g transform="translate(100 100)"><circle fill="',
                '" cx="400.8" cy="200" r="200"/><path fill="',
                '" d="M600.8 200.4 400 237.6v-74.4z"/><path d="M800 800H0c0-27.13 2.72-54.19 8.126-80.775a399.03 399.03 0 0 1 60.188-143.316 401.281 401.281 0 0 1 175.988-145.212 397.432 397.432 0 0 1 75.083-23.355 403.116 403.116 0 0 1 161.228 0 397.385 397.385 0 0 1 143.03 60.306C734.062 542.181 800.173 666.768 800 800Z" fill="',
                '"/></g><path fill="',
                '" />',
                1000000000000000
            );

            ICONs[7] = ICON("Snow 1",
                '<g transform="translate(300 100)" fill="',
                '"><circle transform="rotate(90 400 400)" cx="400" cy="400" r="200"/><circle cx="200" cy="200" r="200"/></g><g transform="translate(100 300)" fill="',
                '"><circle transform="rotate(90 200 200)" cx="200" cy="200" r="200"/><circle cx="400" cy="400" r="200"/></g><path fill="',
                '"/><path fill="',
                '"/>',
                1000000000000000
            );

            ICONs[8] = ICON("Ball 1",
                '<g transform="translate(100 100)"><circle fill="',
                '" cx="400" cy="400" r="400"/><path d="M800 400C800 179.086 620.914 0 400 0S0 179.086 0 400c0 .8 800 .8 800 0Z" fill="',
                '"/></g><path fill="',
                '" /><path fill="',
                '" />',
                1000000000000000
            );

            ICONs[9] = ICON("Tree 3",
                '<path fill="',
                '" d="M902 1000 662.861 624.68h72.317L500.494 285 265.822 624.68h72.317L99 1000z"/><g transform="translate(176 124)" fill="',
                '"><path d="m331.903 4.966 14.365 29.101a8.819 8.819 0 0 0 6.677 4.812l32.123 4.668a8.879 8.879 0 0 1 4.909 15.134L366.733 81.37a8.914 8.914 0 0 0-2.551 7.855l5.486 31.988a8.854 8.854 0 0 1-12.8 9.348l-28.731-15.098a8.88 8.88 0 0 0-8.266 0l-28.73 15.098a8.856 8.856 0 0 1-12.861-9.348l5.486-31.988a8.89 8.89 0 0 0-2.563-7.855l-23.232-22.653a8.866 8.866 0 0 1 4.909-15.134l32.123-4.668a8.819 8.819 0 0 0 6.677-4.812l14.281-29.137a8.879 8.879 0 0 1 15.942 0Z"/><ellipse cx="429.788" cy="613.112" rx="37.212" ry="37.209"/><ellipse cx="37.212" cy="714.791" rx="37.212" ry="37.209"/></g><g transform="translate(345 399)" fill="',
                '"><ellipse cx="37.242" cy="37.239" rx="37.242" ry="37.239"/><ellipse cx="155.697" cy="172.89" rx="37.242" ry="37.239"/><ellipse cx="49.186" cy="338.002" rx="37.242" ry="37.239"/><ellipse cx="440.758" cy="439.761" rx="37.242" ry="37.239"/></g><g transform="translate(462 399)" fill="',
                '"><ellipse cx="143.789" cy="37.258" rx="37.211" ry="37.258"/><ellipse cx="37.211" cy="497.742" rx="37.211" ry="37.258"/></g>',
                1000000000000000
            );
            ICONs[9] = ICON("Tree 3",
                '<path fill="',
                '" d="M902 1000 662.861 624.68h72.317L500.494 285 265.822 624.68h72.317L99 1000z"/><g transform="translate(176 124)" fill="',
                '"><path d="m331.903 4.966 14.365 29.101a8.819 8.819 0 0 0 6.677 4.812l32.123 4.668a8.879 8.879 0 0 1 4.909 15.134L366.733 81.37a8.914 8.914 0 0 0-2.551 7.855l5.486 31.988a8.854 8.854 0 0 1-12.8 9.348l-28.731-15.098a8.88 8.88 0 0 0-8.266 0l-28.73 15.098a8.856 8.856 0 0 1-12.861-9.348l5.486-31.988a8.89 8.89 0 0 0-2.563-7.855l-23.232-22.653a8.866 8.866 0 0 1 4.909-15.134l32.123-4.668a8.819 8.819 0 0 0 6.677-4.812l14.281-29.137a8.879 8.879 0 0 1 15.942 0Z"/><ellipse cx="429.788" cy="613.112" rx="37.212" ry="37.209"/><ellipse cx="37.212" cy="714.791" rx="37.212" ry="37.209"/></g><g transform="translate(345 399)" fill="',
                '"><ellipse cx="37.242" cy="37.239" rx="37.242" ry="37.239"/><ellipse cx="155.697" cy="172.89" rx="37.242" ry="37.239"/><ellipse cx="49.186" cy="338.002" rx="37.242" ry="37.239"/><ellipse cx="440.758" cy="439.761" rx="37.242" ry="37.239"/></g><g transform="translate(462 399)" fill="',
                '"><ellipse cx="143.789" cy="37.258" rx="37.211" ry="37.258"/><ellipse cx="37.211" cy="497.742" rx="37.211" ry="37.258"/></g>',
                1000000000000000
            );

            ICONs[10] = ICON("Skate",
                '<g transform="translate(217 344)" fill="',
                '"><circle cx="541" cy="26" r="26"/><circle cx="26" cy="26" r="26"/><path d="M399.177 508a6.815 6.815 0 0 0-6.81 6.82c-.007 7.476-6.058 13.535-13.525 13.541H369.2v-15.038h-13.61v15.038h-40.983v-15.038h-13.621v15.038H289.81a6.815 6.815 0 0 0-6.811 6.82c0 3.766 3.05 6.819 6.81 6.819h89.044c14.987-.013 27.133-12.175 27.146-27.18 0-1.811-.72-3.548-1.999-4.827a6.806 6.806 0 0 0-4.824-1.993Zm-287.525-24.954a6.744 6.744 0 0 0-3.386-3.9 6.705 6.705 0 0 0-5.142-.35c-7.011 2.349-14.595-1.435-16.961-8.463l-3.018-9.061 14.099-4.788-4.294-12.832-14.087 4.788-12.93-38.58 14.087-4.787-4.294-12.82-14.086 4.788-3.543-10.522c-1.223-3.488-5.011-5.343-8.503-4.165-3.493 1.178-5.395 4.953-4.271 8.474l28.065 83.79c4.733 14.113 19.963 21.71 34.03 16.974 3.515-1.193 5.408-5.013 4.234-8.546Z"/></g><path d="M507 610h55v180h-55zM342.248 764 326 712.236l23.904-7.527c47.645-15.093 82.149-56.61 88.332-106.289V598L492 604.627l-.06.432c-8.801 70.766-57.945 129.91-125.812 151.414L342.248 764ZM436 324.154V205.878L577 205v119.202c0 39.1-31.564 70.798-70.5 70.798a70.338 70.338 0 0 1-49.871-20.75c-13.224-13.288-20.645-31.31-20.629-50.096Z" fill="',
                '"/><path d="M561.962 785v28.74c20.25 3.8 35.65 21.786 35.994 43.516l.006.744h-55v-1h-36v-72h55Zm-205.81-82.984 17.994 52.493-26.884 9.215a44.372 44.372 0 0 1-29.027 48.069l-.546.19-11.694-34.115-.002.002L288 725.377l68.153-23.36ZM438.49 343a70.85 70.85 0 0 0 18.1 31.25A70.338 70.338 0 0 0 506.463 395l1.166-.01c31.942-.52 58.72-22.372 66.822-51.99h135.512v67.836H595.324V613H412.56V410.836H292.962V343H438.49Zm69.297-229 1.12.009c36.889.57 67.446 28.938 70.53 65.71 6.101 1.074 10.543 6.368 10.525 12.545v13.048c0 7.007-5.698 12.688-12.727 12.688H437.69a12.747 12.747 0 0 1-9-3.716 12.669 12.669 0 0 1-3.728-8.972v-13.048c-.029-6.43 4.775-11.862 11.176-12.64 3.162-37.106 34.295-65.62 71.65-65.624Z" fill="',
                '"/><g transform="translate(258 218)" fill="',
                '"><rect x="452" y="118" width="35" height="79" rx="8.91"/><rect y="118" width="35" height="79" rx="8.91"/><path d="M197 0v14.294C197 42.07 222.142 67 250.196 67h-.06C278.19 67 300 42.07 300 14.294V.012L197 0Zm52 217c5.523 0 10-4.477 10-10s-4.477-10-10-10-10 4.477-10 10 4.477 10 10 10Zm.012 21a10 10 0 1 0 9.988 9.988 10 10 0 0 0-9.988-9.988ZM249 280c-5.523 0-10 4.477-10 10s4.477 10 10 10 10-4.477 10-10c-.007-5.52-4.48-9.993-10-10Z"/></g><g transform="translate(484 233)"><circle cx="7.5" cy="7.5" r="7.5"/><circle cx="41.5" cy="7.5" r="7.5"/></g>',
                1000000000000000
            );

            ICONs[11] = ICON("Gifts",
                '<path fill="',
                '" d="M168.84 0H497.2v561.28H168.84z" transform="translate(251.4 219.77)"/><path fill="',
                '" d="M0 234.95h337.68v326.32H0z" transform="translate(251.4 219.77)"/><path d="M204.6 353.32V235.06c30.244-12.925 45.377-47.008 34.68-78.11a62.7 62.7 0 0 0-64.77 15 63.46 63.46 0 0 0-5.65 6.48 63.46 63.46 0 0 0-5.65-6.48 62.7 62.7 0 0 0-64.77-15c-10.697 31.102 4.436 65.185 34.68 78.11v118.26H0v71.48h133.1v136.43h71.5V424.8h133.1v-71.48H204.6Z" fill="',
                '" transform="translate(251.4 219.77)"/><path d="M412.2 110.1a41.89 41.89 0 0 0 29.65-51.32 41.9 41.9 0 0 0-51.33 29.64 41.88 41.88 0 0 0-51.32-29.64 41.87 41.87 0 0 0 29.65 51.32 41.89 41.89 0 0 0-29.65 51.33 41.89 41.89 0 0 0 51.32-29.65 41.91 41.91 0 0 0 51.33 29.65 41.91 41.91 0 0 0-29.65-51.33Z" fill="',
                '" transform="translate(251.4 219.77)"/>',
                1000000000000000
            );

            ICONs[12] = ICON("Glasses",
                '<path d="M388.675 526.155 359.986 514l-68.59 161.446-41.227-17.48L238 686.623l111.132 47.105 12.169-28.645-41.216-17.481zM756.64 753.883l-43.845 9.146-35.86-171.69-30.506 6.363 35.86 171.68-43.833 9.146 6.36 30.472L763 784.355z" fill="',
                '"/><g fill="',
                '"><path d="m416.591 191.014 163.89 69.568-104.75 246.777c-19.214 45.266-71.486 66.386-116.752 47.17-45.246-19.226-66.347-71.485-47.138-116.737l104.75-246.779Z"/><path d="m508.847 299.818 174.311-36.384 54.78 262.445c10.048 48.139-20.831 95.307-68.969 105.355a89.04 89.04 0 0 1-105.354-68.969l-54.78-262.444.012-.002Z"/></g><path d="M363.087 316.992 527 386.57l-51.278 120.802c-19.214 45.266-71.485 66.385-116.752 47.17-45.266-19.214-66.386-71.485-47.171-116.752l51.277-120.8.01.004Z" fill="',
                '"/><path d="m535.582 427.924 174.323-36.386L737.95 525.89c10.038 48.121-20.82 95.272-68.936 105.336a89.04 89.04 0 0 1-105.354-68.969l-28.041-134.341-.036.007Z" fill="',
                '"/>',
                1000000000000000
            );

            ICONs[13] = ICON("Snow 2",
                '<path d="M797.86 456.09 786.69 408l-82.94 19.2 33.5-53.74-41.93-26.14L635.69 443l-59.82 13.88a86.73 86.73 0 0 0-27.44-29.43l17.95-58.7 99.55-52.91-23.19-43.63-55.92 29.72 24.9-81.42-47.24-14.45-24.91 81.42-29.73-55.92-43.62 23.19 52.91 99.55-17.95 58.7a86.56 86.56 0 0 0-39.36 9.12l-41.9-44.89 3.88-112.68-49.38-1.7-2.18 63.3-58.1-62.24L278 297.62l58.1 62.24-63.3-2.18-1.7 49.38 112.68 3.88 41.89 44.88a86.66 86.66 0 0 0-11.78 38.65l-59.8 13.88-95.68-59.64-26.14 41.93 53.73 33.5-82.9 19.25 11.17 48.13 82.94-19.25-33.5 53.73 41.93 26.14 59.64-95.68 59.82-13.89A86.53 86.53 0 0 0 452.54 572l-18 58.7L335 683.64l23.19 43.63 55.92-29.73L389.24 779l47.25 14.46 24.9-81.46 29.73 55.93 43.63-23.19-52.92-99.56 18-58.69a86.68 86.68 0 0 0 39.35-9.12l41.91 44.89-3.88 112.68 49.38 1.7 2.18-63.3 58.1 62.24L723 701.86l-58.1-62.25 63.29 2.18 1.7-49.38-112.67-3.87-41.9-44.88A86.5 86.5 0 0 0 587.06 505l59.8-13.88 95.68 59.64 26.13-41.93-53.75-33.51 82.94-19.23Zm-264.21 53.79a34.68 34.68 0 1 1-23-43.31c18.305 5.615 28.6 25 23 43.31Z" fill="',
                '"/><path fill="',
                '"/><path fill="',
                '"/><path fill="',
                '"/>',
                1000000000000000
            );

            ICONs[14] = ICON("Gift",
                '<path d="M412.09 733.7v25c-18.429 3.497-31.767 19.603-31.77 38.36h80.59V733.7h-48.82Zm129.65 25.03v-25h-48.82v63.39h80.59c.032-18.776-13.32-34.91-31.77-38.39Zm-67.38-400.01c43.986.006 79.64 35.664 79.64 79.65v194.69H394.71V438.37c0-43.99 35.66-79.65 79.65-79.65Z" fill="',
                '"/><path d="M509 228.14a41.44 41.44 0 1 0-79.8 4A56.776 56.776 0 1 0 476 335.6a56.75 56.75 0 1 0 33-107.46Zm-45.67 582.13h-13.46v-13.18h-12v13.18h-36v-13.18H390v13.18h-4.78c-6.555-.005-11.869-5.315-11.88-11.87a6 6 0 1 0-11.95 0c.017 13.153 10.678 23.81 23.83 23.82h78.12a6 6 0 1 0 0-12l-.01.05Zm123.15-17.85a6 6 0 0 0-6 6c-.005 6.554-5.317 11.865-11.87 11.87h-4.79v-13.2h-11.93v13.18h-36v-13.18H504v13.18h-13.5a6 6 0 0 0 0 12h78.13c13.149-.016 23.804-10.671 23.82-23.82a6 6 0 0 0-5.97-6.03ZM451.7 396.07h163.57v123.37H451.7z" fill="',
                '"/><g transform="translate(429.05 276.32)" fill="',
                '"><path d="M.38 0v36c0 26.82 24 50.89 50.85 50.89 26.82 0 47.66-24.07 47.66-50.89V0H.38Zm83.94 119.75h40.23v123.37H84.32z"/><circle cx="22.65" cy="203.3" r="22.65"/><circle cx="186.22" cy="203.3" r="22.65"/></g><path d="M412.505 633.05h48v105h-48zm129.065 105H493.1v-105h48.47zM429.43 314.21h210.15v89.4H429.43z" fill="',
                '"/><g transform="translate(443.27 294.61)"><circle cx="56.64" cy="6.36" r="6.36"/><circle cx="25.31" cy="6.36" r="6.36"/><circle cx="8.43" cy="79.46" r="8.43"/><path d="M35.39 40.47a8.43 8.43 0 1 0 0 16.86 8.43 8.43 0 0 0 0-16.86Z"/><circle cx="134.65" cy="83.47" r="8.43"/><circle cx="110.74" cy="43.29" r="8.43"/><circle cx="76.19" cy="75.03" r="8.43"/><circle cx="165.89" cy="46.3" r="8.43"/></g>',
                1000000000000000
            );

            ICONs[15] = ICON("Candy",
                '<path d="M322.608 849 244 770.477l385.286-384.865a53.03 53.03 0 0 0 14.064-51.411c-4.892-18.416-19.291-32.8-37.727-37.686a53.166 53.166 0 0 0-51.468 14.048l-22.98 22.955-78.595-78.523 22.98-22.942c64.164-64.08 168.184-64.07 232.334.025 64.151 64.095 64.14 168-.025 232.082L322.61 849Z" fill="',
                '"/><path fill="',
                '" d="m492.321 522.428 124.662 32.519-25.974 25.945-124.662-32.519zm255.42-225.813-102.633 52.607a52.972 52.972 0 0 0-1.758-15.021 52.991 52.991 0 0 0-7.227-15.95l98.8-50.646a162.897 162.897 0 0 1 12.818 29.01ZM580.624 184.372l.529 111.486a53.12 53.12 0 0 0-26.998 14.705l-4.59 4.585-.597-125.524a164.925 164.925 0 0 1 31.656-5.252Zm13.392 236.472 136.161 15.649a164.743 164.743 0 0 1-22.308 27.667l-1.47 1.467-140.995-16.202 28.612-28.581ZM284.162 730.359l124.662 32.519-25.973 25.945-124.663-32.519zM388.285 626.35l124.991 32.191-26.066 26.037-124.99-32.192z"/><path fill="',
                '"/><path fill="',
                '"/>',
                1000000000000000
            );

            ICONs[16] = ICON("Ball 2",
                '<circle fill="',
                '" cx="500.5" cy="574.5" r="294.5"/><path d="m268.898 393 521.259 232.081c-8.18 48.637-28.282 93.228-57.198 130.664L210 522.906c8.805-48.477 29.477-92.818 58.898-129.906Z" fill="',
                '"/><path d="M727.66 217.564c11.226-25.187 4.347-54.79-16.826-72.403-21.172-17.614-51.451-18.926-74.059-3.208-22.607 15.717-32.005 44.615-22.987 70.679l-16.722-7.52a26.16 26.16 0 0 0-20.069-.583 26.262 26.262 0 0 0-14.6 13.822L534 281.829 696.626 355l28.397-63.464a26.377 26.377 0 0 0 .587-20.135 26.275 26.275 0 0 0-13.788-14.65l-16.707-7.52a61.023 61.023 0 0 0 32.545-31.667Zm-27.242-12.294c-7.117 15.818-25.663 22.866-41.445 15.751s-22.836-25.705-15.764-41.543c7.072-15.838 25.598-22.94 41.4-15.87a31.272 31.272 0 0 1 16.59 17.516 31.394 31.394 0 0 1-.781 24.146Z" fill="',
                '"/><path fill="',
                '"/>',
                1000000000000000
            );

            ICONs[17] = ICON("Tree 4",
                '<path fill="',
                '" d="M0 1000h1000V-1H826.307z"/><g transform="translate(429 113)" fill="',
                '"><circle cx="82" cy="716" r="82"/><path d="M571 14.257C536.894-9.04 490.806-3.26 463.488 27.74c-27.317 31-27.317 77.519 0 108.518 27.318 31 73.406 36.78 107.512 13.484V14.257Z"/></g><g transform="translate(418 335)" fill="',
                '"><circle cx="82" cy="82" r="82"/><path d="M582 558.215c-31.26-21.294-73.051-18.415-101.09 6.962-28.04 25.378-35.024 66.645-16.895 99.823H582V558.215Z"/></g><circle fill="',
                '" cx="790" cy="582" r="82"/>',
                1000000000000000
            );

            ICONs[18] = ICON("Wreath",
                '<path d="M839.774 512.895a42.555 42.555 0 0 0-20.52-32.228 42.61 42.61 0 0 0 5.806-37.747 42.624 42.624 0 0 0-26.771-27.242 42.623 42.623 0 0 0-2.193-38.139 42.642 42.642 0 0 0-31.872-21.07 42.612 42.612 0 0 0-10.071-36.826 42.634 42.634 0 0 0-35.531-13.987 42.603 42.603 0 0 0-17.47-33.938 42.624 42.624 0 0 0-37.65-6.33 42.583 42.583 0 0 0-24.145-29.613 42.6 42.6 0 0 0-38.177 1.665 42.649 42.649 0 0 0-66.783-14.33 42.569 42.569 0 0 0-34.09-17.11h-.763a42.543 42.543 0 0 0-34.128 17.086 42.534 42.534 0 0 0-36.975-9.655 42.424 42.424 0 0 0-29.897 23.831 42.6 42.6 0 0 0-38.175-1.767 42.583 42.583 0 0 0-24.225 29.55 42.65 42.65 0 0 0-37.677 6.239 42.629 42.629 0 0 0-17.569 33.902 42.609 42.609 0 0 0-35.587 13.88 42.587 42.587 0 0 0-10.154 36.818 42.591 42.591 0 0 0-31.924 20.972 42.572 42.572 0 0 0-2.268 38.123 42.624 42.624 0 0 0-26.874 27.178 42.61 42.61 0 0 0 5.718 37.786 42.626 42.626 0 0 0-7.128 67.86 42.626 42.626 0 0 0 7.065 67.873 42.649 42.649 0 0 0-5.744 37.768 42.662 42.662 0 0 0 26.81 27.221 42.661 42.661 0 0 0 2.272 38.123 42.68 42.68 0 0 0 31.882 21.036 42.561 42.561 0 0 0 10.107 36.813 42.583 42.583 0 0 0 35.559 13.91 42.578 42.578 0 0 0 17.49 33.937 42.599 42.599 0 0 0 37.667 6.281 42.583 42.583 0 0 0 24.23 29.67 42.6 42.6 0 0 0 38.27-1.8 42.636 42.636 0 0 0 66.808 14.24A42.708 42.708 0 0 0 499.137 890a42.518 42.518 0 0 0 34.104-17.048 42.636 42.636 0 0 0 66.846-14.075 42.65 42.65 0 0 0 38.203 1.807 42.634 42.634 0 0 0 24.285-29.538 42.637 42.637 0 0 0 37.663-6.217 42.616 42.616 0 0 0 17.583-33.874 42.621 42.621 0 0 0 35.551-13.868 42.6 42.6 0 0 0 10.191-36.766 42.642 42.642 0 0 0 31.951-20.937 42.623 42.623 0 0 0 2.355-38.12 42.586 42.586 0 0 0 26.89-27.148 42.573 42.573 0 0 0-5.709-37.778 42.614 42.614 0 0 0 7.23-67.873 42.55 42.55 0 0 0 13.494-35.67ZM386.32 548.019c-.006-45.781 27.575-87.057 69.88-104.58 42.306-17.522 91.003-7.839 123.383 24.534 32.38 32.372 42.064 81.058 24.538 123.353-17.526 42.296-58.811 69.87-104.603 69.865-62.515-.007-113.191-50.672-113.198-113.172Z" fill="',
                '"/><g transform="translate(206 225)" fill="',
                '"><path d="m353 143-58.5-38.304L236 143V0h117z"/><circle cx="306" cy="568" r="31"/><circle cx="31" cy="351" r="31"/></g><g transform="translate(302 110)" fill="',
                '"><path d="M333 0 197.5 63.33 62 0v190l135.5-63.33L333 190z"/><circle cx="31" cy="621" r="31"/><circle cx="441" cy="438" r="31"/></g><g transform="translate(267 354)" fill="',
                '"><circle cx="31" cy="42" r="31"/><circle cx="415" cy="31" r="31"/><circle cx="403" cy="373" r="31"/></g>',
                1000000000000000
            );

            ICONs[19] = ICON("Biscuit",
                '<path d="M802.175 372.242H576.994c55.785-34.82 81.736-102.352 63.61-165.529C622.477 143.536 564.659 100 498.884 100c-65.776 0-123.595 43.536-141.721 106.713-18.127 63.177 7.824 130.709 63.609 165.53H196.774c-39.316-.323-71.449 31.26-71.774 70.544-.32 39.283 31.29 71.39 70.605 71.713h173.782L292.6 784.32c-8.803 30.95-.412 64.24 22.012 87.333 22.424 23.092 55.474 32.477 86.7 24.62 31.227-7.858 55.886-31.765 64.69-62.714l30.333-106.666 30.361 106.638c8.508 31.302 33.202 55.616 64.652 63.655 31.449 8.04 64.795-1.437 87.303-24.81 22.507-23.374 30.699-57.034 21.446-88.124L623.27 514.527h177.736c39.014-.114 70.671-31.577 70.994-70.558.318-38.981-30.818-70.96-69.825-71.713v-.014Z" fill="',
                '"/><g transform="translate(449 189)" fill="',
                '"><circle cx="21" cy="21" r="21"/><circle cx="86" cy="24" r="21"/><path d="M97.817 71c.604.003 1.18.248 1.592.68.412.43.624 1.008.587 1.597C98.753 98.335 77.609 118.021 51.959 118 26.31 117.979 5.2 98.257 4 73.197a2.122 2.122 0 0 1 .623-1.55A2.217 2.217 0 0 1 6.193 71h91.624Z"/></g><g transform="translate(474 435)" fill="',
                '"><circle cx="27" cy="27" r="27"/><circle cx="27" cy="142" r="27"/></g><path fill="',
                '"/>',
                1000000000000000
            );


            ICONs[20] = ICON("Star 2",
                '<g><path fill="',
                '" d="M424.489 410.228 163.048 377.05l222.061 141.774-159.805 210.463 234.206-118.64 101.616 243.414 15.348-264.194 261.494 33.266-222.077-141.956 159.825-210.235-234.218 118.502-101.715-243.497z"/><path fill="',
                '" d="m465.536 405.254-201.183-103.54 137.524 179.588-190.73 122.872 223.792-26.942 10.505 226.22 89.961-208.64 201.201 103.626-137.483-179.74L789.8 396.016l-223.76 26.828-10.56-226.317z"/><path fill="',
                '" d="m430.187 549.702-40.875 188.532 117.553-152.887 143.279 129.96-71.573-178.357 183.987-58.571-191.678-28.047 40.942-188.566-117.687 152.887-143.111-129.96 71.472 178.357-184.054 58.638z"/><path fill="',
                '" d="m464.108 448.517-138.044-29.929L438.01 504.66l-95.16 104.91 130.594-52.406 42.886 134.715 20.536-140.346 138.069 29.977-111.945-86.17 95.158-104.787-130.594 52.332-42.935-134.764z"/></g>',
                1000000000000000
            );

            ICONs[21] = ICON("Nordic Trees",
                '<g><path fill="',
                '" d="m618.03 196 203.002 804.806H415.03z"/><path fill="',
                '" d="m154.813 557.23 154.812 443.576H0z"/><path fill="',
                '" d="m395.266 387.045 154.813 613.761H240.454z"/><path fill="',
                '" d="M838.05 583.58 1000 1000.807H676.101z"/></g>',
                1000000000000000
            );

            number_of_icons = 21;


        // NGOs
            NGOs[1]  = NGO(0xc3e302e8FDa21b9C020e6388d8052C8055530AdA, "Save the Children");
            NGOs[2]  = NGO(0x63BBc9a8a5D3f66277d9553B73453f59A3C5EcA0, "Coral Restoration Foundation");
            NGOs[3]  = NGO(0xE9bc9DdcEd5685B3871d52EaD8253C4BeA78B935, "Stichting The Ocean Cleanup");
            NGOs[4]  = NGO(0xCdB1cd005918CB00514F3d31872fe40443A52c8c, "Pollinator Partnership Canada");
            NGOs[5]  = NGO(0xcD26C12578B3FDF80D4203CD932e99825F218E6B, "FundLife International");
            NGOs[6]  = NGO(0xB41077c30a1cD16b04776740806Fe2BA18E7AD8D, "AfricAid");
            NGOs[7]  = NGO(0xfA371b51f11B9B32AD597d7c43A302107F66bf94, "National PCF");
            NGOs[8]  = NGO(0x777e24f9d6Aa4CBe853079935560C8c5B80f9B42, "Fondazione Umberto Veronesi");
            NGOs[9]  = NGO(0x496c13C7Ab3cD4Ea167062956da08cade3A562dF, "Global Impact");
            NGOs[10] = NGO(0x8d53637779338c27FC41c323defe8dB4F8dFdDf0, "International Medical Corps");
            NGOs[11] = NGO(0xA4166BC4Be559b762B346CB4AAad3b051E584E39, "Razom");
            NGOs[12] = NGO(0x968DC9065969bBf2652639658b963E287336bF34, "Operation Broken Silence");
            NGOs[13] = NGO(0x36f66F445340E1d58419c6d5EeB71a19323B88e4, "Autism Speaks");
            NGOs[14] = NGO(0xaF3e16a5bf3320A919A6f67c85954d94EA70224e, "Girls Who Code");
            NGOs[15] = NGO(0xf6285e6a3293b4C658F19cC6cAA9123cF5190a84, "2535 Water");

            number_of_NGOs = 15;


            COLORs[0]  = '#000000';
            COLORs[1]  = '#2D2D2D';
            COLORs[2]  = '#144100';
            COLORs[3]  = '#006657';
            COLORs[4]  = '#ef4046';
            COLORs[5]  = '#FF5A00';
            COLORs[6]  = '#85d1ff';
            COLORs[7]  = '#e0b82f';
            COLORs[8]  = '#fde9f1';
            COLORs[9]  = '#EBE6DC';
            COLORs[10] = '#FFFFFF';
            
            number_of_colors = 10;

    }
    
    string private constant BG_1     = '<svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000"><g stroke="none" fill="none"><rect fill="';
    string private constant BG_2     = '" x="0" y="0" width="1000" height="1000"></rect></g>';
    string private constant TEXT_1   = '<g stroke="none" stroke-width="1" font-family="Helvetica, Arial" font-size="83" font-weight="normal" letter-spacing="0.0166" line-spacing="79"><text x="60" y="1.5em" fill="#FFFFFF">';
    string private constant TX_1     = '</text></g><g stroke="none" stroke-width="1" font-family="Helvetica, Arial" font-size="30" font-weight="normal" letter-spacing="0.0166" line-spacing="79"><text x="50%" y="950" dominant-baseline="middle" text-anchor="middle" fill="#FFFFFF">';
    string private constant TX_2     = '</text></g>';

    function baseTokenURI() override public pure returns (string memory) { return ""; }

    // Concat functions
        function con(string memory s_1, string memory s_2) internal pure returns (string memory) {
             return string(s_1.toSlice().concat(s_2.toSlice()));
        }
        function con(string memory s_1, string memory s_2, string memory s_3) internal pure returns (string memory) {
             return con(con(s_1,s_2),s_3);
        }
        function con(string memory s_1, string memory s_2, string memory s_3, string memory s_4) internal pure returns (string memory) {
             return con(con(s_1,s_2,s_3),s_4);
        }
        function con(string memory s_1, string memory s_2, string memory s_3, string memory s_4, string memory s_5) internal pure returns (string memory) {
             return con(con(s_1,s_2,s_3,s_4),s_5);
        }
        function con(string memory s_1, string memory s_2, string memory s_3, string memory s_4, string memory s_5, string memory s_6) internal pure returns (string memory) {
             return con(con(s_1,s_2,s_3,s_4,s_5),s_6);
        }

    function getTOKEN(uint256 _tokenId) public view returns (string memory) {
        
        Card   memory card = get_card(_tokenId);

        string memory   bg   = con(BG_1,   COLORs[card.bg_color], BG_2);
        
        string memory   icon;
        icon = con(ICONs[card.icon_id].part_1, COLORs[card.icon_color_1], ICONs[card.icon_id].part_2, COLORs[card.icon_color_2], ICONs[card.icon_id].part_3);
        icon = con(icon,     COLORs[card.icon_color_3], ICONs[card.icon_id].part_4, COLORs[card.icon_color_4], ICONs[card.icon_id].part_5);

        string memory txt  = con(TEXT_1, card.message);

        string memory dona = con(TX_1, DONAs[card.donated], ' ETH donated to ', NGOs[card.NGO_id].name, TX_2);

        string memory svg = con(bg, icon, txt, dona, '</svg>');

        return string(abi.encodePacked('","image":"data:image/svg+xml;base64,',Base64.encode(bytes(svg))));
        
    }

    function getAttributes(uint256 _tokenId) public view returns (string memory) {
        
        Card   memory card = get_card(_tokenId);

        string memory json = con( '", "attributes":[  {"trait_type":"Donated to","value":"', NGOs[card.NGO_id].name);
        json = con( json,'"},{"trait_type":"Donated amount","value":"', DONAs[card.donated], ' ETH"},' );
        json = con( json, '{"trait_type":"Icon","value":"', ICONs[card.icon_id].name, '"}]}' );

        return json;

    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            con('{"name":"Xmas Card #', Strings.toString(_tokenId), '",'), 
                            con('"description":"This unique NFT certifies that', DONAs[get_card(_tokenId).donated], ' ETH were donated to ', NGOs[get_card(_tokenId).NGO_id].name),
                            getTOKEN(_tokenId), 
                            getAttributes(_tokenId)
                        )
                    )
                )
            )
        );
    }

   function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        '{"name":"Donate Xmas","description":"Create your NFT Christmas postcard and donate to an NGO","image":"","external_link":"https://donate-xmas.com","seller_fee_basis_points":0,"fee_recipient":""}'
                    )
                )
        ));
    }


    // Donation
    function donate(uint256 amount, uint256 NGO_id) internal{
        payable(NGOs[NGO_id].addr).transfer(amount);
    }

    // Mint
    function mint_card(
        address _to,
        string  memory _message, 
        uint256 _NGO_id, 
        uint256 _icon_id, 
        uint256 _bg_color, 
        uint256 _icon_color_1, 
        uint256 _icon_color_2,
        uint256 _icon_color_3,
        uint256 _icon_color_4
    ) external payable returns(uint256 _token_id) {
        require(msg.value >= ICONs[_icon_id].min_donation, "Minimum donation amount not crossed");
        require( bytes(DONAs[msg.value]).length > 0, "Donation amount should be one of 0.05, 0.1, 0.25, 0.5, 1, 5, or 10 ETH");
        uint256 token_id = mintTo(_to, _message, msg.value, _NGO_id, _icon_id, _bg_color, _icon_color_1, _icon_color_2, _icon_color_3, _icon_color_4);
        donate(msg.value, _NGO_id);
        return token_id;
    }

    // Add new icons and NGOs after publication

    function add_icon(
        string memory name,
        string memory part_1,
        string memory part_2,
        string memory part_3,
        string memory part_4,
        string memory part_5,
        uint256 min_donation
    ) external returns(uint256 _number_of_icons) {
        require(msg.sender == owner(), 'Only the owner can do this');
        number_of_icons = number_of_icons.add(1);
        ICONs[number_of_icons] = ICON(name, part_1, part_2, part_3, part_4, part_5, min_donation);
        emit new_ICON(number_of_icons);
        return number_of_icons;
    }

    function add_color(
        string memory color_hex
    ) external returns(uint256 _number_of_colors) {
        require(msg.sender == owner(), 'Only the owner can do this');
        number_of_colors = number_of_colors.add(1);
        COLORs[number_of_colors] = color_hex;
        emit new_COLOR(number_of_colors);
        return number_of_colors;
    }

    function add_NGO(
        string memory name,
        address addr
    ) external returns(uint256 _number_of_NGOs) {
        require(msg.sender == owner(), 'Only the owner can do this');
        number_of_NGOs = number_of_NGOs.add(1);
        NGOs[number_of_NGOs] = NGO(addr, name);
        emit new_NGO(number_of_NGOs);
        return number_of_NGOs;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
//import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
//import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
import "./Base64.sol";
import "./strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    //using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;

    event Created(uint256 tokenId, address receiver, uint256 amount, uint256 NGO_id);

    struct Card {
        address creator;
        string  message;
        uint256 donated;
        //string dona;
        uint256 NGO_id;
        uint256 icon_id;
        uint256 bg_color;
        uint256 icon_color_1;
        uint256 icon_color_2;
        uint256 icon_color_3;
        uint256 icon_color_4;
    }

    mapping(uint256 => Card) private cards_list;


    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    /**
     * @dev Mints a card to an address with a tokenURI.
     * @param _to address of the future owner of the card
     */
    function mintTo(
        address _to, 
        string  memory _message, 
        uint256 _amount, 
        uint256 _NGO_id, 
        uint256 _icon_id, 
        uint256 _bg_color, 
        uint256 _icon_color_1,
        uint256 _icon_color_2,
        uint256 _icon_color_3,
        uint256 _icon_color_4

    ) internal returns(uint256 _token_id) {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
        //string memory dona = Strings.toString(_amount/10**14);
        cards_list[_currentTokenId] = Card(msg.sender, _message, _amount, _NGO_id, _icon_id, _bg_color, _icon_color_1, _icon_color_2, _icon_color_3, _icon_color_4);
        emit Created(newTokenId, _to, _amount, _NGO_id);
        return newTokenId;
    }

    // Views
    function read_card(uint256 card_id) public view returns(string memory) {
        return cards_list[card_id].message;
    }

    function get_card(uint256 card_id) public view returns(Card memory) {
        return cards_list[card_id];
    }

    function _getNextTokenId() private view returns (uint256) { return _currentTokenId + 1; }
    function _incrementTokenId() private { _currentTokenId++; }

    function baseTokenURI() virtual public pure returns (string memory);

    function tokenURI(uint256 _tokenId) override public view virtual returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        string memory table = TABLE_ENCODE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");
        bytes memory table = TABLE_DECODE;
        uint256 decodedLen = (data.length / 4) * 3;
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }
            mstore(result, decodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */
 // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint _len) private pure {
        // Copy word-length chunks while possible
        for(; _len >= 32; _len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (_len > 0) {
            mask = 256 ** (32 - _len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = type(uint).max; // 0xffff...
                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint diff = (a & mask) - (b & mask);
                    if (diff != 0)
                        return int(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0)
            return "";

        uint length = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            length += parts[i]._len;

        string memory ret = new string(length);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}