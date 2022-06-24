// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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