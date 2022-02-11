// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Ownable.sol";

//   
//    ______     __   __     ______     __  __     ______     __     __   __    
//   /\  __ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\  __ \   /\ \   /\ "-.\ \   
//   \ \ \/\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \  __ \  \ \ \  \ \ \-.  \  
//    \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_\\"\_\ 
//     \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/\/_/   \/_/   \/_/ \/_/ 
//                                                                              
//    __    __     ______     __   __     __  __     ______     __  __          
//   /\ "-./  \   /\  __ \   /\ "-.\ \   /\ \/ /    /\  ___\   /\ \_\ \         
//   \ \ \-./\ \  \ \ \/\ \  \ \ \-.  \  \ \  _"-.  \ \  __\   \ \____ \        
//    \ \_\ \ \_\  \ \_____\  \ \_\\"\_\  \ \_\ \_\  \ \_____\  \/\_____\       
//     \/_/  \/_/   \/_____/   \/_/ \/_/   \/_/\/_/   \/_____/   \/_____/       
//                                                                              
//   
// 
// OnChainMonkey (OCM) Genesis was the first 100% On-Chain PFP collection in 1 transaction 
// (contract: 0x960b7a6BCD451c9968473f7bbFd9Be826EFd549A)
// 
// created by Metagood
//
// OCM Desserts is a 100% On-Chain collection in 1 transaction too! It is one that OCM Genesis 
// can eat (burn) to create the new Karma collection.
//
// OCM Desserts, being On-Chain, will also live forever, just like OCM Genesis. However,
// the Desserts will need to be burned to create Karma, so the Dessert supply will be 
// decreasing over time as people burn their Desserts.
//
//
//                            .';cllllc;'.                               
//                       .;dOXMMMMMMMMMMMMXOl'                           
//                     ,xNMMMMMMMMMMMMMMMMMMMMNk,                        
//                   ;0MMMMMMMMMMMMMMMMMMMMMMMMMM0;                      
//                 .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                    
//                .KMMMMMMMMMMMMMMMMMMMXo;',c0MMMMMMK.                   
//               ;NMMMMMMMMMMMMMMMMMMM0.      :NMMMMMK.                  
//              lWMMMMMMNd:,;ckWMMMMMMd        oMMMMMMd                  
//             xXWMMMMM0.      ;WMMMMMX.       .XMMMMMWlclll:,.          
//           .Ox;MMMMMMo        dMMMMMMd        cMMMMMMMMMMMMMW0o'       
//          .0d 'MMMMMMK.       .NMMMMMN.        0MMMMMMMMMMMMMMMMO.     
//          Ox   XMMMMMMl        lMMMMMMx        ;MMMMMMMOxkXMMMMMMN'    
//         :N.   lMMMMMMN.       .KMMMMMW,        kMMMMMMc   :NMMMMM0    
//         lK   .cWMMMMMMd        :MMMMMMO        ,WMMMMMX.   cMMMMMM'   
//         ;N:lKWMMMMMMMMW'        0MMMMMM:        xMMMMMMl   xMMMMMN.   
//          KWMMMMMMMMMMMMk        ;WMMMMMK        .NMMMMMN,;OMMMMMMd    
//        .kMMMMMMXOWMMMMMW;        kMMMMMMl        oMMMMMMMMMMMMMMd     
//       ,KMMMMMNc  kMMMMMM0        'WMMMMMX.       .XMMMMMMMMMMMWl      
//      :NWMMMMMd   'WMMMMMMd        dMMMMMMd        cMMMMMMW0OWN:       
//     oK,OMMMMM0.   dMMMMMMW;       .NMMMMMW.        0MMMMMWoK0.        
//    d0. .XMMMMMXl'.;WMMMMMM0        lMMMMMMx        ;MMMMMMMk.         
//   ;W'   .KMMMMMMMMMMMMMMMMMc       .KMMMMMWc        kMMMMMMc          
//   oX      cKMMMMMMMMMMMMMMMK.       :MMMMMMN.       ,WMMMMMX.         
//   :W'       'lx0XNXNMMMMMMMMl        0MMMMMMk       'WMMMMMMo         
//    k0.            .OOKMMMMMMN.       ;MMMMMMMx.    ;KMMMMMMMN'        
//     dK;          .0x ;WMMMMMMd       'WMMMMMMMMX00NMMMMMMMMMMK.       
//      'x0d,.     'Kl   kMMMMMMWd.    ,KMMMMMMMMMMMMMMMMMMMMMMMMo       
//         'lddddooKO    'WMMMMMMMWKO0NMMMMMMMMMMMMMMMMMMMWX0xdNN:       
//                 ,N,    dMMMMMMMMMMMMMMMMMMMMMMMMWXOdl;'.  .OO.        
//                  x0    .NMMMMMMMMMMMMMMMMN0kdc;..        .0x          
//                  .Nc    lMMMMMMMMWX0xo:'.  .';:     .';ldKl           
//                   lX.   'WWXOxl;'.   ,:ok0NMMMMdoxxxxo:,.             
//                   .Ko  'Kk.         .0MMMMMMMMMN,.                    
//                    :N.;Kc    .';ldxxxkWMMMMMMMMMl                     
//                     OXWkcoxxxxo:,.    xMMMMMMMMMX.                    
//                     'xo:,..           .NMMMMMMMMMo                    
//                                        oMMMMMMMMMN.                   
//                                        .XMMMMMMMMM;                   
//                                         ,XMMMMMMWd                    
//                                           ;oxkxl.                     
//                                                                       
//                                                                       
//
//

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract OCMDesserts is ERC1155, Ownable {
    string private svg1='<svg xmlns="http://www.w3.org/2000/svg" width="999" height="999"><path fill="#fff61d" d="M0 0h999v999H0z"/><g><path d="M0-45V0v-45" id="a"/><animateMotion dur="5s" repeatCount="indefinite" keyPoints="0;.50;1;.50;0" keyTimes="0;.25;.50;.75;1" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1" calcMode="spline"><mpath href="#a"/></animateMotion><g fill="#ff8ff9"><path d="m310 443-30 53 42-11-12-42z"/><circle cx="346" cy="532" r="74" transform="rotate(344 346 532)"/></g><path d="m429 667 257-71-30 54-257 72 30-55zm190-204 78-21-38 69-78 21 38-69z" fill="#d0b"/><path d="m399 722 30-55 39-11-103-369-31 54c-13 24-28 46-16 91l81 290z" fill="#ff8ff9"/><path fill="#af8200" d="m506 675 70.172-20.122 28.115 98.049-70.172 20.122z"/><circle cx="376" cy="477" transform="rotate(344 376 477)" fill="#f0f" r="74"/><circle cx="568" cy="765" transform="rotate(344 568 765)" fill="#af8200" r="35"/><g fill="#f0f"><circle cx="632" cy="406" transform="rotate(344 632 406)" r="74"/><circle cx="481" cy="354" r="133" transform="rotate(344 481 354)"/></g><g fill="#d0b"><circle transform="scale(1 -1) rotate(15.543 1935.567 1139.037)" r="30"/><circle transform="scale(1 -1) rotate(15.543 1803.447 2112.435)" r="30"/></g><path fill="#f0f" d="m352 389 257.289-71.353 77.232 278.489-257.289 71.353z"/><path fill="#ffe386" d="m528 728 68.404-19.025 10.45 37.574-68.404 19.025z"/><path fill="#dab754" d="m511 666 68.25-19.57 17.916 62.482-68.25 19.57z"/><circle cx="573" cy="757" transform="rotate(344 573 757)" fill="#ffe386" r="35"/><path d="m511 666-5 9 7-2-2-7z" fill="#af8200"/><g fill="#ff8ff9"><rect x="390" y="325" width="59" height="290" rx="29" transform="rotate(344 390 325)"/><rect x="494" y="296" width="59" height="290" rx="29" transform="rotate(344 494 296)"/></g><path fill-rule="evenodd" d="M365 604c-23 6-47 0-65-14l31-54c18 14 41 19 65 13l-31 55z" fill="#d0b"/></g><ellipse cx="521" cy="895" rx="73" ry="11" fill-opacity=".2"><animate values="73;90;73" keyTimes="0;.50;1" dur="2.5s" attributeName="rx" fill="freeze" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1" calcMode="spline" repeatCount="indefinite"/></ellipse></svg>';
    string private svg2='<svg xmlns="http://www.w3.org/2000/svg" width="999" height="999"><path fill="#f0f" d="M0 0h999v999H0z"/><g><path d="M0-70V0v-70z" id="a"/><animateMotion dur="6s" repeatCount="indefinite" keyPoints="0;.50;1;.50;0" keyTimes="0;.25;.50;.75;1" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1" calcMode="spline"><mpath href="#a"/></animateMotion><circle cx="496" cy="526" transform="rotate(351 496 526)" fill="#db5" r="245"/><mask id="b" maskUnits="userSpaceOnUse" x="256" y="262" width="491" height="491" mask-type="alpha"><circle cx="501" cy="508" r="245" transform="rotate(351 501 508)" fill="#db5"/></mask><g mask="url(#b)"><circle cx="499" cy="496" transform="rotate(351 499 496)" fill="#fe8" r="246"/></g><mask id="c" maskUnits="userSpaceOnUse" x="185" y="439" width="229" height="230" mask-type="alpha"><circle cx="300" cy="554" transform="rotate(351 300 554)" fill="#db5" r="114"/></mask><g mask="url(#c)"><circle cx="297" cy="541" transform="rotate(351 297 541)" fill="#fe8" r="113"/><circle cx="301" cy="527" transform="rotate(351 301 527)" fill="#5cf" r="96"/></g><mask id="d" maskUnits="userSpaceOnUse" x="621" y="371" width="227" height="226" mask-type="alpha"><circle cx="734" cy="484" transform="rotate(351 734 484)" fill="#db5" r="113"/></mask><g mask="url(#d)"><circle cx="705" cy="486" transform="rotate(351 705 486)" fill="#fe8" r="111"/><circle cx="711" cy="467" transform="rotate(351 711 467)" fill="#5cf" r="95"/></g><mask id="e" maskUnits="userSpaceOnUse" x="257" y="267" width="491" height="491" mask-type="alpha"><path d="M744 473c21 134-69 259-203 281-133 21-259-69-281-203-21-133 69-259 203-281 134-21 259 70 281 203z" fill="#db5"/></mask><g mask="url(#e)"><circle cx="502" cy="473" transform="rotate(351 502 473)" fill="#5cf" r="221"/><circle cx="504" cy="455" transform="rotate(351 504 455)" fill="#67d9fd" r="203"/></g><g fill="#67d9fd"><circle cx="306" cy="509" transform="rotate(351 306 509)" r="71"/><circle cx="711" cy="443" transform="rotate(351 711 443)" r="71"/></g><circle cx="500" cy="466" transform="rotate(351 500 466)" fill="#fe8" r="50"/><mask id="f" maskUnits="userSpaceOnUse" x="450" y="415" width="101" height="102" mask-type="alpha"><circle cx="500" cy="466" r="50" transform="rotate(351 500 466)" fill="#fe8"/></mask><g mask="url(#f)"><circle cx="483" cy="504" transform="rotate(351 483 504)" fill="#db5" r="60"/><circle cx="479" cy="510" transform="rotate(351 479 510)" fill="#f0f" r="43"/></g><path fill-rule="evenodd" d="M540 498c11-11 16-27 13-43-4-28-31-48-59-43-24 4-41 23-43 45 6-16 20-28 37-31 27-4 53 14 57 41 2 11 0 22-5 31z" fill="#5cf"/><path d="m369 367 33.871 2.963-.61 6.973-33.871-2.963zm168-51-32.54 9.856-2.029-6.699 32.54-9.856z" fill="#f0f"/><path d="m431 319 27.507 19.985-4.114 5.663-27.507-19.985zm79 51 31.016-13.928 2.867 6.386-31.016 13.928zm-96 137-11.721-31.916 6.571-2.413 11.721 31.916z" fill="#fe0"/><path d="m458 393-29 17-4-7 29-17 4 7z" fill="#75cc0a"/><path d="m650 467 13.928 31.017-6.386 2.867-13.928-31.017zm-48 116 8.8-32.841 6.761 1.812-8.8 32.841zm1-177-33.129-7.648 1.575-6.821 33.129 7.648z" fill="#f0f"/><path d="m744 434-27.57-19.897 4.096-5.676 27.57 19.897zm-141 14 27.889-19.448 4.004 5.742-27.889 19.448z" fill="#fe0"/><path d="m579 500 32 8-1 7-33-8 2-7zm20-157 24 24-5 5-24-24 5-5zm97 111 31-14 3 7-31 14-3-7z" fill="#75cc0a"/><path d="m502 562-33.871-2.963.61-6.973 33.871 2.963zM368 438l-17 29.445-6.062-3.5 17-29.445z" fill="#f0f"/><path d="m423 596 2.963-33.871 6.973.61-2.963 33.871zm-124-60-27.923-19.399 3.994-5.749 27.923 19.399zm271 16-21.307 26.495-5.455-4.387 21.307-26.495z" fill="#fe0"/><path d="m385 550-17-29 7-4 17 29-7 4zm-88-46 31-14 3 7-31 13-3-6zm226 116-29-17 3-7 30 17-4 7z" fill="#75cc0a"/><g fill="#fff"><path d="M582 298c13 1 42 42 42 42-11-17-27-43-26-53 2-10 13-23 18-26 0 0-19 12-29 9-11-2-39-40-39-40 9 13 26 43 23 52s-16 22-23 28c0 0 22-13 34-12z"><animate attributeName="opacity" values="1;0;1" dur="1s" repeatCount="indefinite"/></path><path d="M236 510c13 2 41 41 41 41-11-16-26-41-25-51 2-10 13-22 17-25 0 0-18 11-28 8-10-2-38-39-38-39 9 13 25 43 22 51-2 9-15 21-22 27 0 0 21-13 33-12z"><animate attributeName="opacity" values="0;1;0" dur="1s" repeatCount="indefinite"/></path></g></g><ellipse cx="500" cy="880" rx="149" ry="17" fill-opacity=".2"><animate values="149;190;149" keyTimes="0;.50;1" dur="3s" attributeName="rx" fill="freeze" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1" calcMode="spline" repeatCount="indefinite"/></ellipse></svg>';
    string private svg3='<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="999" height="999"><style>.B{fill:#fc0}.C{fill:#fff}.D{fill-rule:evenodd}</style><path fill="#0a4" d="M0 0h999v999H0z"/><path d="M293 0h402l224 919H79L293 0Z" fill="#7c0"/><ellipse cx="499" cy="920" rx="420" ry="44" fill="#bf4"/><g><path d="M0-30V0v-30z" id="a"/><animateMotion dur="8s" repeatCount="indefinite" keyPoints="0;.50;1;.50;0" keyTimes="0;.25;.50;.75;1" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1" calcMode="spline"><mpath href="#a"/></animateMotion><g fill="#083"><path d="m350 225 42 14 10-20-11-18-45-8-13 14-7 28 20-11 2-9 2 10zm94-95 3 60 30 3 17-24-12-59-25-10-38 5 23 19 14-1-12 7z"/><path d="m495 211 8 35 18-1 8-16-14-34-15-3-22 7 16 9 7-2-6 5zm-100 20-21 19 36-4 32-37-20-33-29-12-32 12 20 17 5 16c4 9 9 22 9 22z"/><path d="m522 178-13 20-27-8-7-26 19-47 29 1 23 21-23 8-7 21 6 10zm31 71-17 22-30-11-6-31 26-53 33 3 26 27-28 7-11 24 7 12z"/><path d="m550 147 32 29-29-2-3-12-1 13-26 7-8-13 5 15-17 20-7-3 13-43 41-11zm11 68 48 29-33 4-9-15 5 17-27 13-14-14 11 17-10 29-9-2-3-56 41-22zm-201 16-32 44 36-10v-17l4 17 34 2 7-18-2 20 26 22 8-6-27-51-54-3zm44-113-57 32 41 7 10-18-5 20 32 17 17-15-14 19 14 35 11-2 2-67-51-28zm75 91-32 14 23 7 6-10-3 11 19 12 9-8-7 10 8 21 6-1 1-37-30-19z"/></g><g class="B D"><path d="M365 214c43 5 83-22 94-65 1-4 2-7 3-11 11 15 15 34 10 53-8 33-42 53-74 44-14-3-25-11-33-21z"/><path d="M378 254c49-8 86-52 85-103 0-5-1-9-1-13 17 13 28 33 28 56 1 39-30 72-69 73-16 0-31-5-43-13z"/></g><path d="M472 217c11-26-2-58-10-75 6 23-7 56-19 71-8 9-16 26-60 39 41 11 76-6 89-35zm-27-18c7-9 15-28 15-53-6 30-21 42-33 52-9 5-20 15-61 16 35 12 65 2 79-15z" fill="#ff2"/><g class="D"><path d="M451 280c38-32 46-89 18-132-2-3-4-6-7-10 21 2 41 13 53 32 22 33 13 77-20 99-14 9-29 12-44 11z" class="B"/><path d="M459 260c28-23 34-69 12-109-2-5-5-9-7-12 19 4 37 20 45 43 12 33 1 68-25 77-8 3-17 3-25 1z" fill="#ff2"/></g><path d="m586 177 14-1-12 86-14-2 12-83z" fill="#b80"/><g fill="#0a3"><path d="m570 175 30-3-44 37 14-34z"/><path d="m617 175-29-3 33 37-4-34z"/><path d="m587 154 9 21-52-7 43-14z"/><path d="m604 154-15 21 53-8-38-13z"/></g><path fill="#b80" d="m336 203-11.6 3.071 27.01 69.968 11.6-3.071z"/><g fill="#0a3"><path d="m349 199-25 4 44 22-19-26z"/><path d="m310 209 24-9-20 39-4-30z"/><path d="m331 184-3 21 41-19-38-2z"/><path d="m317 188 17 15-46 5 29-20z"/></g><path d="M566.19 244.48h-27.48v10.99h27.48v-10.99z" class="C"/><g class="B"><use xlink:href="#B"/><use xlink:href="#B" x="10.99"/></g><use xlink:href="#C" class="C"/><path d="M538.73 232.32a1.89 1.89 0 1 0 0-3.79 1.89 1.89 0 1 0 0 3.79z" class="B"/><use xlink:href="#C" x="27.48" class="C"/><path d="M566.17 232.32a1.895 1.895 0 0 0 0-3.79 1.89 1.89 0 1 0 0 3.79z" class="B"/><path d="M552.45 244.48a13.74 13.74 0 0 0 0-27.48 13.74 13.74 0 1 0 0 27.48z" class="C"/><path d="M552.45 241.78a10.88 10.88 0 1 0 0-21.76 10.88 10.88 0 1 0 0 21.76z" class="B"/><g class="C"><use xlink:href="#D"/><use xlink:href="#D" x="9.46"/></g><path d="M547.32 228.68a1.965 1.965 0 1 0-1.97-1.97 1.97 1.97 0 0 0 1.97 1.97zm9.39-.14a1.895 1.895 0 1 0-1.9-1.9 1.9 1.9 0 0 0 1.9 1.9z" class="B"/><use xlink:href="#E"/><use xlink:href="#E" x="9.46"/><path d="M560.49 223.8h-16.08v2.84h16.08v-2.84z" class="B"/><path d="M552.45 239.77c4.12 0 7.46-1.41 7.46-3.14 0-1.74-3.34-3.14-7.46-3.14s-7.46 1.4-7.46 3.14c0 1.73 3.34 3.14 7.46 3.14z" class="C"/><g fill="#caa000"><use xlink:href="#F"/><use xlink:href="#F" x="-3.14"/></g><path d="M557.65 237.05h-10.4v.95h10.4v-.95z" class="B"/><g class="C"><path d="m322 290 276.942-24.229 9.936 113.566-276.942 24.229z"/><ellipse cx="460" cy="278" rx="139" ry="21" transform="rotate(355 460 278)"/></g><g class="B"><ellipse cx="468" cy="366" rx="139" ry="21" transform="rotate(355 468 366)"/><path d="m330 378 276.942-24.229 4.794 54.791-276.942 24.229z"/><circle cx="237" cy="743" transform="rotate(355 237 743)" r="73"/><circle cx="763" cy="696" transform="rotate(175 763 696)" r="73"/></g><g fill="#da0"><circle transform="scale(1 -1) rotate(5.064 8519.427 2308.205)" r="29"/><circle transform="matrix(-.9961 .08827 .08827 .9961 763 696)" r="29"/></g><path d="m228.481 640.757 525.991-46.018 16.908 193.262-525.991 46.018z" class="C"/><path d="M202 679c-24 13-39 40-37 70 3 29 23 53 49 62l-12-132zm597 80c25-14 40-40 38-70-3-29-22-53-49-63l11 133z" fill="#ff2" class="D"/><g class="C"><path d="m275 448 399.474-34.949 14.206 162.38-399.474 34.949z"/><ellipse cx="475" cy="430" rx="200" ry="31" transform="rotate(355 475 430)"/></g><g class="B"><ellipse cx="484" cy="540" rx="200" ry="29" transform="rotate(355 484 540)"/><path d="m285 559 399.474-34.949 5.055 57.779-399.474 34.949z"/></g><ellipse cx="491" cy="616" rx="264" ry="41" transform="rotate(355 491 616)" class="C"/><g class="B"><ellipse cx="503" cy="745" rx="264" ry="43" transform="rotate(355 503 745)"/><path d="m240 771 525.991-46.018 5.317 60.768-525.991 46.018z"/></g><ellipse cx="509" cy="811" rx="264" ry="41" transform="rotate(355 509 811)" fill="#da0"/><path d="m434 134 18-19 15 24-7 7-26-12z" class="B"/><path d="m233 689 32-76m-32 76 32-76m13 129 71-148m-71 148 71-148m19 126 66-139m-66 139 66-139m24 126 64-135m-64 135 64-135m32 127 59-130m-59 130 59-130m31 128 60-123m-60 123 60-123m24 130 29-65m-29 65 29-65m4.616 44.32-94.797-113.655m94.797 113.655-94.797-113.655M688 700 577 570m111 130L577 570m18 128L488 576m107 122L488 576m11 126L395 586m104 116L395 586m14 128L307 601m102 113L307 601m12 130-88-98m88 98-88-98" stroke="#da0"/><g class="B"><circle cx="384" cy="685" r="6"/><circle cx="419" cy="613" r="6"/><circle cx="510" cy="601" r="6"/><circle cx="601" cy="598" r="6"/><circle cx="692" cy="601" r="6"/><circle cx="474" cy="673" r="6"/><circle cx="568" cy="666" r="6"/><circle cx="660" cy="664" r="6"/><circle cx="746" cy="666" r="6"/><circle cx="297" cy="705" r="6"/><circle cx="333" cy="629" r="6"/><circle cx="248" cy="654" r="6"/></g><path d="m327 348 36-77m-36 77 36-77m34 82 41-94m-41 94 41-94m49 83 33-88m-33 88 33-88m48 88 28-79m-28 79 28-79m-219 95-56-70m56 70-56-70m133.595 58.294-59.323-81.742m59.323 81.742-59.323-81.742M536 341l-56-86m56 86-56-86m124 75-50-76m50 76-50-76" stroke="#da0"/><g class="B"><circle cx="343" cy="314" r="6"/><circle cx="421" cy="300" r="6"/><circle cx="505" cy="293" r="6"/><circle cx="584" cy="298" r="6"/></g><path d="m336 533 51-8 10 67-53 7-8-66zm-31 200 51-10 9 65-52 11-8-66zm75-377 51-8 8 56-53 7-6-55z" fill-opacity=".3" class="C"/><path d="m481 705 45-5 8 67-47 4-6-66z" fill="#ff2"/><path d="m487 764 46-4 1 7-47 4v-7z" fill="#da0"/><g class="B"><path d="m624 677-48 2 10 57 49-2-11-57z"/><ellipse cx="596" cy="684" rx="29" ry="14" transform="rotate(352 596 684)"/></g><g fill="#da0"><ellipse cx="608" cy="740" rx="28" ry="10" transform="rotate(345 608 740)"/><path d="m605 752-79 14 60-28 19 14z"/></g><g class="B"><path d="m576 676-49 24 7 62 53-26-11-60zm-193 28 40-11 3 61-40 9-3-59z"/><ellipse rx="28" ry="11" transform="matrix(-.99462 .1036 .10703 .99426 412 702)"/></g><g fill="#da0"><ellipse rx="28" ry="10" transform="matrix(-.99987 -.01602 -.0042 .99999 414 763)"/><path d="m420 773 83-6-79-14-4 20z"/></g><path d="m423 691 59 14 6 60-63-12-2-62z" class="B"/><g><animate attributeName="opacity" values="0;1;0" dur="1s" repeatCount="indefinite"/><g class="C"><path d="M436 137c4 0 13 13 13 13-3-5-8-13-8-17 1-3 4-7 6-8 0 0-6 4-9 3-4-1-13-13-13-13 3 4 8 14 7 17 0 3-5 7-7 9 0 0 7-5 11-4zM283 561c7 1 23 23 23 23-6-9-15-23-14-29s7-12 10-14c0 0-11 6-17 5-5-2-21-23-21-23 5 8 14 25 13 30-2 5-9 12-13 15 0 0 12-7 19-7zm15 247c7 1 23 23 23 23-6-8-15-23-14-29s7-13 10-14c0 0-11 6-16 5-6-2-22-23-22-23 5 7 14 25 13 30-2 5-9 12-13 15 0 0 12-7 19-7zm493-175c5 0 16 16 16 16-4-6-10-17-10-21 1-4 5-9 7-10 0 0-7 5-11 4s-16-17-16-17c4 6 10 18 9 21-1 4-6 9-9 12 0 0 9-6 14-5z"/><use xlink:href="#A"/></g></g><g><animate attributeName="opacity" values="1;0;1" dur="1s" repeatCount="indefinite"/><g class="C"><path d="M605 732c5 1 18 18 18 18-5-7-11-18-11-22 1-5 6-10 8-11 0 0-9 4-13 3s-17-17-17-17c4 6 11 19 10 23-1 3-7 9-10 12 0 0 10-6 15-6zm80-204c5 0 17 18 17 18-4-7-11-18-10-23 0-4 5-10 7-11 0 0-8 5-12 4-5-1-17-17-17-17 4 5 11 18 10 22-2 4-7 10-10 12 0 0 9-6 15-5zM167 729c6 0 20 20 20 20-6-8-13-21-13-26 1-4 7-10 9-12 0 0-9 6-14 4-5-1-19-19-19-19 5 6 13 21 11 25-1 5-7 11-11 14 0 0 11-7 17-6z"/><use xlink:href="#A" x="-224" y="-135"/><path d="M502 180c8 0 26 25 26 25-7-10-17-26-16-32 1-7 8-14 11-16 0 0-12 7-18 5-7-1-25-25-25-25 7 8 17 27 15 33-2 5-10 13-15 17 0 0 14-8 22-7z"/></g></g></g><ellipse cx="499" cy="922" rx="215" ry="24" fill="#0a4"><animate values="230;250;230" keyTimes="0;.50;1" dur="4s" attributeName="rx" fill="freeze" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1" calcMode="spline" repeatCount="indefinite"/></ellipse><defs><path id="A" d="M605 358c5 0 17 17 17 17-4-7-11-18-10-22 0-4 5-10 7-11 0 0-8 5-12 4-5-1-17-17-17-17 4 5 11 18 10 22s-7 9-10 12c0 0 9-6 15-5z"/><path id="B" d="M547.06 250.81c.28 0 .5-.22.5-.5a.5.5 0 0 0-.5-.5.51.51 0 0 0-.5.5.5.5 0 0 0 .5.5z"/><path id="C" d="M538.71 235.06c2.6 0 4.71-2.11 4.71-4.71 0-2.61-2.11-4.71-4.71-4.71s-4.71 2.1-4.71 4.71c0 2.6 2.11 4.71 4.71 4.71z"/><path id="D" d="M547.72 230.43c1.83 0 3.31-1.27 3.31-2.84s-1.48-2.84-3.31-2.84-3.31 1.27-3.31 2.84 1.48 2.84 3.31 2.84z"/><path id="E" d="M547.25 227.59a.94.94 0 1 0 0-1.89.94.94 0 0 0-.95.94c0 .53.42.95.95.95z"/><path id="F" d="M554.02 235.06c.22 0 .39-.18.39-.4a.39.39 0 0 0-.78 0c0 .22.17.4.39.4z"/></defs></svg>';

    address public eatingContract; // allowed to eat/burn Desserts
    address public randomizerContract;
    uint256 private dessertCount = 0; // maximum of 10,000 Desserts can be minted

    constructor() ERC1155("") {}

    // owner will air drop Desserts via this mint function, designed to minimize gas used for multiple mints
    // if ads.length > quantity.length, transaction will fail and no mints will go through
    // if ads.length < quantity.length, the extra values in quantity will be ignored
    function ownerMint(address[] calldata ads, uint256[] calldata quantity, uint256 typeId) external onlyOwner {
        require(typeId>0 && typeId<4, "type err");
        for (uint256 i=0; i<ads.length; i++) {
          require(dessertCount+quantity[i] < 10001, "10k");
          _mint(ads[i], typeId, quantity[i], "");
          dessertCount += quantity[i];
        }
    }

    // owner will air drop Desserts via this mint function, designed to minimize gas used for single mints
    function ownerMint1(address[] calldata ads, uint256 typeId) external onlyOwner {
        require(typeId>0 && typeId<4, "type err");
        require(dessertCount+ads.length < 10001, "10k");
        for (uint256 i=0; i<ads.length; i++) {
          _mint(ads[i], typeId, 1, "");
        }
        dessertCount += ads.length;
    }    

    function setEatingContractAddress(address eatingContractAddress) external onlyOwner {
        eatingContract = eatingContractAddress;
    }

    function setRandomizerContractAddress(address randomizerContractAddress) external onlyOwner {
        randomizerContract = randomizerContractAddress;
    }

    function burnDessertForAddress(uint256 typeId, address burnTokenAddress) external {
        require(msg.sender == eatingContract, "ad err");
        _burn(burnTokenAddress, typeId, 1);
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeId>0 && typeId<4, "type err");
        bytes memory svg;
        string memory num;
        if (typeId == 1) {
            svg = bytes(svg1);
            num = '1 Incredible Ice Pop","attributes":[{"trait_type": "Dessert Type", "value": "D1';
        } else if (typeId == 2) {
            svg = bytes(svg2);
            num = '2 Divine Donut","attributes":[{"trait_type": "Dessert Type", "value": "D2';
        } else {
            svg = bytes(svg3);
            num = '3 Celestial Cake","attributes":[{"trait_type": "Dessert Type", "value": "D3';
        }
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
            '{"name": "D', num, '"}],"image": "data:image/svg+xml;base64,',
            Base64.encode(svg),'"}'))));
    }
}