// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "base64-sol/base64.sol";

interface IExternalStatic {
  function getSVG() external pure returns (string memory);
}


contract BootcampSVG1 is IExternalStatic {
  function getSVG() external override pure returns (string memory) {
    return '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 816 805.4" style="enable-background:new 0 0 816 805.4;" xml:space="preserve">'
    '<style>.st0{fill-rule:evenodd;clip-rule:evenodd;fill:#6b1687}.st1{fill:#883797}.st2{fill:#2800ff}.st3{fill:#68626a}.st4{fill:#67616a}.st5{fill-rule:evenodd;clip-rule:evenodd;}.st17{fill:#666}.st18{font-family:Optima,Helvetica, sans-serif;}.st19{font-size:36px}.st20{letter-spacing:4}.st21{fill:#6c04b4}.st22{letter-spacing:3}.st23{font-size:21px}</style>'
    '<path class="st0" d="m415 129.4l-1.2-2.1"/><path class="st1" d="M86.9,703.7h642.5v2.9H86.9V703.7z"/>'
    '<path class="st1" d="m86.9 698.2c-3.9-0.1-7 3-7.1 6.9s3 7 6.9 7.1 7-3 7.1-6.9v-0.1c0-3.8-3.1-6.9-6.9-7zm642.5 13.9c3.8-0.5 6.6-3.9 6.1-7.8-0.4-3.2-2.9-5.7-6.1-6.1-3.8-0.5-7.3 2.3-7.8 6.1s2.3 7.3 6.1 7.8c0.6 0.1 1.1 0.1 1.7 0z"/>'
    '<path class="st2" d="m544.1 778.6h2.8c0.7 0 0.9-0.2 0.9-0.9v-12.3l1.4 2.3 4.1 7.2c0.2 0.3 0.6 0.6 1 0.6h1.8c0.5 0 1-0.3 1.3-0.7 0.4-0.8 0.8-1.5 1.3-2.2 1.3-2.4 2.6-4.8 4-7.1 0-0.1 0-0.1 0.1-0.1v12.4c0 0.6 0.2 0.8 0.8 0.8h2.8c0.7 0 0.9-0.2 0.9-0.9v-19.8c0-0.6-0.3-0.9-0.8-0.9-1 0.1-2 0.1-3 0-0.6 0-1.1 0.3-1.4 0.8l-2.8 4.9-2.5 4.4-0.3 0.7c-0.3 0.6-0.6 1.2-1 1.8l-0.2-0.3c-0.3-0.7-0.7-1.3-1.1-1.9l-2.8-4.7c-0.8-1.7-1.8-3.3-2.8-4.9-0.1-0.5-0.6-0.8-1.1-0.7h-3.2c-0.4-0.1-0.7 0.2-0.8 0.6v0.2 20.1c-0.2 0.4 0 0.6 0.6 0.6zm-38.9 0h6c1.3 0.1 2.6-0.2 3.8-0.7 2.6-1 4.7-2.8 6-5.3 1.6-3.3 1.5-7.3-0.5-10.4-1.7-2.7-4.4-4.5-7.5-5-0.7-0.1-1.3-0.2-2-0.2h-5.8c-0.6 0-0.8 0.3-0.8 0.8v20.1c0 0.5 0.2 0.7 0.8 0.7zm3.5-16.8c0-0.2 0.1-0.3 0.3-0.3 0.5 0.1 1.1 0.1 1.6 0.1s1.1 0 1.6 0.1c0.8 0.1 1.6 0.3 2.2 0.8 2.2 1.2 3.4 3.6 3.1 6-0.1 1.7-0.9 3.3-2.3 4.4-1.1 1-2.5 1.5-4 1.5h-2.2c-0.2 0-0.3 0-0.3-0.2v-12.4zm-70 16.6l1.7-3.8c0.1-0.1 0.1-0.2 0.3-0.2h9.4l0.5 0.2 1.6 3.8c0.1 0.1 0.1 0.2 0.3 0.2h4.6c-0.1-0.3-0.2-0.5-0.3-0.8l-2.3-5.3-2.3-5.2-2.3-5.3-1.9-4.4c-0.2-0.5-0.6-0.8-1.1-0.8h-2.5c-0.6 0-1.2 0.3-1.4 0.9l-2.2 4.8-2.2 5.2c-0.7 1.8-1.6 3.4-2.3 5.3l-2.1 4.7c-0.1 0.3-0.2 0.5-0.3 0.8h4.6c0.2 0.1 0.2 0 0.2-0.1zm6.8-15.4l3.1 6.9h-6.1l3-6.9zm36.8 15.4c0.6-1.2 1.1-2.4 1.6-3.7 0.1-0.2 0.3-0.3 0.5-0.3h9.4l0.5 0.2 1.6 3.8c0 0.1 0.1 0.2 0.2 0.2h4.7c-0.1-0.3-0.2-0.5-0.3-0.8l-2.3-5.2-2.3-5.3-2.2-4.8-2.2-4.9c-0.1-0.4-0.5-0.7-1-0.7-0.4 0.1-0.9 0.1-1.3 0.1s-0.9 0-1.3-0.1c-0.6 0-1.1 0.3-1.3 0.9l-2.2 4.8-2.3 5.2-2.3 5.4c-0.7 1.5-1.4 3-1.9 4.5-0.2 0.3-0.4 0.6-0.5 0.9h4.6c0.2 0 0.2-0.1 0.3-0.2zm6.7-15.4l3.1 6.9h-6.1l3-6.9zm37.9 15.6h11.1c0.6 0 0.8-0.2 0.8-0.8v-2.8c-0.1-0.7-0.2-0.9-0.9-0.9h-7.1c-0.3 0-0.3-0.1-0.3-0.3v-3.4c0-0.2 0-0.3 0.2-0.3h5.8c0.6 0 0.8-0.2 0.8-0.8v-2.9c0-0.6-0.2-0.8-0.8-0.8h-5.7c-0.3 0-0.3-0.1-0.3-0.3v-3.4c0-0.2 0-0.3 0.3-0.3h7.1c0.7 0 0.9-0.2 0.9-0.8v-2.9c0-0.5-0.3-0.8-0.9-0.8h-11c-0.6 0-0.8 0.3-0.8 0.9v19.9c0 0.5 0.2 0.7 0.8 0.7zm-62.5-0.4c1.1 0.3 2.2 0.5 3.3 0.5s2.3-0.2 3.3-0.7c1.7-0.7 3.2-1.7 4.5-3.1 0.2-0.3 0.2-0.6 0-0.9l-2.1-2.2c-0.2-0.2-0.3-0.3-0.5-0.3s-0.4 0.1-0.6 0.3c-0.4 0.5-0.8 1-1.4 1.3-1 0.7-2.2 1.1-3.5 1.1-1.5 0-2.9-0.5-4-1.5-2.7-2.4-2.9-6.5-0.5-9.2 1.1-1.2 2.7-2 4.4-2.1 1.1 0 2.1 0.3 3.1 0.8 0.7 0.5 1.3 1 1.9 1.6 0.2 0.2 0.3 0.3 0.5 0.3s0.3-0.1 0.5-0.3l2.1-2.2c0.3-0.2 0.2-0.6 0-0.9l-0.6-0.6c-1.5-1.5-3.4-2.5-5.5-3-0.6-0.1-1.2-0.2-1.8-0.2-3.9 0-7.6 2.2-9.5 5.6-1.7 3.2-1.7 7.2 0 10.4 1.4 2.5 3.7 4.4 6.4 5.3zm108-15.5c1.1 1.8 2.4 3.6 3.6 5.3 0.8 1.4 1.7 2.8 2.6 4.1 0.2 0.4 0.3 0.8 0.3 1.2v4.6c0 0.6 0.2 0.8 0.8 0.8h2.8c0.7 0 0.9-0.2 0.9-0.8v-4.6c0-0.4 0.1-0.8 0.3-1.2l3-4.6 3.6-5.4 3.1-4.6c0.1-0.1 0.2-0.3 0.2-0.5h-5l-0.3 0.1c0 0.1 0 0.2-0.1 0.3l-3.6 5.4-3.1 4.6-0.2 0.5c-0.2 0-0.2-0.3-0.3-0.5l-3.7-5.5c-0.9-1.5-1.9-3-3-4.5-0.1-0.1-0.1-0.1-0.1-0.2-0.1-0.2-0.2-0.2-0.5-0.2h-4.9l0.2 0.5c1.1 1.8 2.2 3.5 3.4 5.2z"/>';
  }
}

contract BootcampSVG2 is IExternalStatic {
  function getSVG() external override pure returns (string memory) {
    return '<path class="st3" d="m258.6 780.5c6.2 0 11.3-5.1 11.3-11.3v-0.2c-0.1-6.2-5.3-11.2-11.5-11.1s-11.2 5.3-11.1 11.5 5.1 11.1 11.3 11.1zm0-20.7h0.2c5 0.1 9.1 4.3 9 9.3-0.1 5.1-4.2 9.2-9.3 9.1s-9.2-4.2-9.1-9.3c0.1-5 4.2-9.1 9.2-9.1z"/>'
    '<path class="st4" d="m322.2 779.2h12.5c0.5 0 0.8-0.3 0.9-0.8 0.3-0.5 0.2-1.1-0.3-1.4-0.2-0.1-0.5-0.2-0.8-0.1h-11.1c-0.2 0-0.3 0-0.3-0.2v-7.7c0-0.2 0.1-0.3 0.3-0.3h7.9c0.6 0 1-0.2 1.1-0.7 0.2-0.8-0.2-1.5-1-1.5h-7.9c-0.3 0-0.5-0.1-0.5-0.5l0.1-7.2c0-0.5-0.1-0.5 0.3-0.5h11.2c0.5 0 0.9-0.3 1-0.8 0.2-0.6-0.2-1.3-0.9-1.5h-0.4-12.4c-0.7-0.1-1.2 0.4-1.3 1.1v0.3 20.4c0.3 0.9 0.7 1.4 1.6 1.4z"/>'
    '<path class="st3" d="m413.9 778.2c1.2 0.7 2.6 1 4 1 1.6 0 3.2-0.5 4.6-1.4 0.5-0.3 1.1-0.7 1.5-1.2 2.4-2.3 2.6-6.1 0.3-8.5-0.2-0.3-0.5-0.5-0.8-0.7-1.2-1-2.6-1.8-4.1-2.1-1-0.1-2.1-0.3-3.1-0.6-1.1-0.3-2.2-0.9-3-1.7-0.5-0.5-0.7-1.2-0.5-1.8 0.2-0.9 0.8-1.7 1.6-2.1 1.1-0.6 2.3-0.9 3.6-1 1.2 0 2.3 0.3 3.4 0.8 1 0.5 1.7 1.5 1.9 2.6 0 0.4 0.2 0.7 0.5 0.9 0.2 0.1 0.4 0.2 0.6 0.2s0.3 0 0.5-0.1c0.3-0.2 0.6-0.6 0.6-1s0-0.7-0.1-1.1c-0.6-1.6-1.8-2.9-3.3-3.6-1.3-0.6-2.7-1-4.2-1-1.6 0.1-3.2 0.5-4.6 1.4-0.5 0.3-1.1 0.7-1.5 1.2-1.7 1.8-1.6 4.7 0.2 6.4 0.1 0.1 0.3 0.2 0.4 0.3 1.2 0.9 2.5 1.5 4 1.8 1.1 0.1 2.1 0.3 3.1 0.7 1 0.2 1.9 0.7 2.6 1.4 0.8 0.7 1.4 1.6 1.6 2.6 0.3 1.4-0.3 2.8-1.4 3.6-1.2 1-2.7 1.6-4.3 1.6-0.9 0-1.8-0.2-2.7-0.5-2-0.5-3.4-2.4-3.4-4.5 0-0.6-0.5-1-1-1s-1 0.5-1 1c0 0.6 0.1 1.1 0.2 1.7 0.5 2.1 1.9 3.8 3.8 4.7zm-45.7 0c1.2 0.7 2.6 1 4 1 1.6 0 3.1-0.5 4.5-1.3 0.6-0.3 1.2-0.7 1.6-1.3 2.5-2.2 2.7-6 0.5-8.5-0.2-0.3-0.5-0.5-0.8-0.7-1.2-1-2.6-1.8-4.2-2.1l-2.4-0.3c-1.2-0.3-2.3-0.8-3.2-1.6-0.6-0.4-0.9-1-0.9-1.7 0.1-0.9 0.5-1.8 1.3-2.3 0.9-0.6 2.1-1 3.2-1 0.4-0.1 0.7-0.1 1.1-0.1 1.2 0 2.3 0.3 3.3 0.9 0.9 0.5 1.6 1.4 1.7 2.5 0 0.4 0.2 0.7 0.5 0.9 0.2 0.1 0.4 0.2 0.6 0.2s0.3 0 0.5-0.1c0.3-0.2 0.6-0.6 0.6-1 0-0.5 0-1-0.2-1.4-0.5-1.5-1.7-2.7-3.2-3.3-1.4-0.7-2.9-1-4.5-1-1.5 0-3 0.5-4.2 1.4-0.6 0.3-1.1 0.7-1.5 1.2-1.1 1.1-1.5 2.7-1.1 4.2 0.3 1 0.9 1.9 1.7 2.5 1.1 1 2.5 1.6 4 1.8 1.1 0.1 2.1 0.3 3.1 0.7 0.9 0.3 1.8 0.8 2.6 1.4 0.9 0.8 1.5 1.9 1.6 3.1 0 1.4-0.7 2.6-1.8 3.4-1.1 0.9-2.5 1.3-3.9 1.3-0.6 0-1.3-0.1-1.9-0.2-1.5-0.2-2.8-1.1-3.6-2.4-0.4-0.7-0.7-1.5-0.7-2.3-0.1-0.5-0.5-0.9-1-0.9-0.5 0.1-0.9 0.5-0.9 1 0 0.6 0 1.2 0.2 1.7 0.3 1.9 1.6 3.6 3.4 4.3zm-65.7 0c2.7 1.4 5.9 1.3 8.5-0.2 0.6-0.3 1.2-0.8 1.7-1.3 2.5-2.3 2.6-6.3 0.3-8.8-0.2-0.2-0.4-0.4-0.6-0.5-1.2-0.9-2.7-1.6-4.2-1.9-1-0.1-2.1-0.3-3.1-0.6-1.1-0.3-2.2-0.9-3-1.7-0.5-0.5-0.7-1.2-0.5-1.8 0.2-0.9 0.8-1.7 1.6-2.1 1.1-0.6 2.3-0.9 3.6-1 1.2 0 2.3 0.3 3.4 0.8 1 0.5 1.8 1.5 2 2.6 0 0.2 0.1 0.4 0.2 0.6 0.1 0.3 0.4 0.6 0.8 0.6 0.7 0 1-0.5 1.1-1.1 0-0.4-0.1-0.7-0.2-1.1-0.5-1.6-1.7-2.9-3.2-3.6-1.4-0.7-2.9-1.1-4.4-1-1.6 0-3.1 0.5-4.5 1.3-0.6 0.3-1.1 0.8-1.5 1.3-1 1.1-1.5 2.5-1.3 4 0.2 1.1 0.9 2 1.8 2.6 1.1 1 2.5 1.6 4 1.9 1.1 0.1 2.1 0.3 3.1 0.6 0.9 0.4 1.8 0.9 2.6 1.5 0.9 0.7 1.5 1.8 1.6 3 0.1 1.3-0.5 2.5-1.5 3.3-1.2 0.9-2.7 1.5-4.3 1.5-0.9 0-1.8-0.2-2.6-0.5-1.4-0.4-2.5-1.4-3.1-2.8-0.2-0.5-0.3-1.1-0.3-1.7-0.1-0.5-0.5-1-1.1-0.9-0.5 0.1-0.9 0.5-0.9 1 0 0.6 0.1 1.1 0.2 1.7 0.7 1.9 2 3.4 3.8 4.3zm-74.3 0c1.3 0.6 2.7 0.9 4.1 1 2.1 0.1 4.2-0.4 6-1.4 1-0.7 2-1.5 2.9-2.3 0.2-0.2 0.3-0.4 0.3-0.7 0.1-0.4-0.1-0.9-0.5-1.1-0.1-0.1-0.3-0.1-0.4-0.1-0.2 0-0.5 0.1-0.7 0.2s-0.4 0.3-0.6 0.5c-1.7 1.7-3.9 2.6-6.3 2.6-0.6 0-1.3-0.1-1.9-0.2-2.6-0.4-4.8-2-6.1-4.2-0.9-1.4-1.4-3-1.4-4.6 0-2 0.5-3.9 1.6-5.6 1.8-2.5 4.6-3.9 7.6-3.9 0.6 0 1.2 0.1 1.8 0.2 1.3 0.3 2.5 0.9 3.6 1.7l1.4 1c0.2 0.2 0.4 0.3 0.7 0.3s0.5-0.1 0.7-0.3c0.4-0.4 0.5-1 0.1-1.4l-0.3-0.3c-0.9-1-2.1-1.8-3.3-2.4-1.4-0.7-2.9-1-4.4-1h-0.7c-1.7 0-3.4 0.4-4.9 1.3-2.2 1.2-3.9 3.1-5 5.3-0.7 1.6-1.1 3.4-1.1 5.2 0.1 1.9 0.6 3.7 1.5 5.4 1.3 2.1 3.1 3.8 5.3 4.8z"/>'
    '<path class="st4" d="m342.5 779.1h0.2c0.5-0.1 1-0.5 0.9-1.1v-13.4c0-0.9 0.1-1.7 0.5-2.5 0.9-2.3 3.2-3.7 5.6-3.7h0.8c2.7 0.4 4.9 2.6 5.3 5.3v14.3c0 0.3 0.1 0.6 0.3 0.8 0.2 0.3 0.6 0.4 0.9 0.4h0.3c0.5-0.1 0.9-0.6 0.8-1.1v-13.5c0-0.8-0.1-1.6-0.3-2.3-0.6-2.1-2.1-3.9-4-5-1.2-0.7-2.6-1-4-1-0.4 0-0.9 0-1.3 0.1-1.2 0.2-2.4 0.7-3.4 1.5-0.4 0.3-0.8 0.6-1.1 1-1.6 1.6-2.4 3.8-2.3 6v13.5c-0.2 0.3 0.3 0.7 0.8 0.7zm-65.4 0c0.1 0 0.3 0 0.4-0.1 0.5-0.1 0.9-0.6 0.8-1.1v-13.3c0-0.8 0.1-1.6 0.3-2.3 0.9-2.4 3.1-4 5.7-4 0.5 0 1 0.1 1.5 0.2 2.7 0.8 4.5 3.2 4.5 6v13.5c-0.1 0.4 0.2 0.8 0.6 0.9 0.2 0.1 0.5 0.2 0.7 0.2s0.3 0 0.5-0.1c0.3-0.2 0.6-0.6 0.6-1v-13.8c0-0.7-0.1-1.4-0.3-2.1-0.6-2.2-2.1-4-4.1-5-1.1-0.7-2.3-1.1-3.6-1.1-0.5 0-1 0-1.5 0.1-1.2 0.2-2.4 0.6-3.4 1.4-0.4 0.3-0.8 0.6-1.1 1-1.6 1.6-2.4 3.8-2.4 6v13.4c-0.2 0.4-0.1 0.9 0.3 1.1 0.1 0.1 0.3 0.1 0.5 0.1z"/>'
    '<path class="st3" d="m388.2 762.7l4 5.3 1.5 1.9c0.1 0.2 0.2 0.4 0.2 0.6v7.7c0.1 0.6 0.3 0.8 0.8 0.9h0.3c0.3 0 0.6-0.1 0.8-0.4s0.2-0.6 0.2-0.9v-7.5c0-0.2 0-0.3 0.1-0.5 0.7-0.8 1.3-1.6 1.9-2.4 1.4-1.8 2.8-3.4 4.1-5.3l1.7-2.2 1.7-2.2c0.3-0.5 0.2-1.2-0.2-1.6-0.2-0.1-0.4-0.2-0.6-0.2-0.3 0-0.7 0.2-0.9 0.4l-0.7 0.9-4.1 5.3-2.4 3-1.7 2.3-0.5-0.6c-1.7-2.2-3.4-4.5-5.2-6.6l-3.2-4.2c-0.2-0.3-0.5-0.4-0.8-0.4h-0.3c-0.6 0.2-0.9 0.8-0.7 1.4 0 0.2 0.1 0.3 0.2 0.4l3.8 4.9z"/>';
  }
}

contract BootcampSVG3 is IExternalStatic {
  function getSVG() external override pure returns (string memory) {
    return '<linearGradient id="a" x1="-2015" x2="-2015" y1="-84.463" y2="-70.963" gradientTransform="matrix(13.55 0 0 13.55 27662 1276.1)" gradientUnits="userSpaceOnUse"><stop stop-color="#be03ed" offset="0"/><stop stop-color="#7935ad" offset="1"/></linearGradient>'
    '<path class="st5" fill= "url(#a)" d="m413.8 130.1l-108.3 183.7 108.3-45.7v-138z"/>'
    '<linearGradient id="d" x1="-2012.8" x2="-2022.9" y1="-85.293" y2="-75.193" gradientTransform="matrix(14.37 0 0 14.37 29465 1375.5)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#e971ff" offset=".1"/><stop stop-color="#662d91" offset="1"/></linearGradient>'
    '<path d="m522.8 313.8l-108.3-183.7 0.2 137.9 108.1 45.8z" clip-rule="evenodd" fill="url(#d)" fill-rule="evenodd"/>'
    '<linearGradient id="i" x1="-1956.5" x2="-1956.5" y1="-58.447" y2="-48.147" gradientTransform="matrix(10.34 0 0 10.34 20590 876.34)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#662d91" offset="1"/></linearGradient>'
    '<path d="m413.8 268.8l-108.3 45.6 108.3 61.3v-106.9z" clip-rule="evenodd" fill="url(#i)" fill-rule="evenodd"/>'
    '<linearGradient id="g" x1="-1945.9" x2="-1945.9" y1="-58.447" y2="-48.147" gradientTransform="matrix(10.34 0 0 10.34 20590 876.34)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient>'
    '<path d="m414.7 268.8l-0.2 106.9 108.2-61.3-108-45.6z" clip-rule="evenodd" fill="url(#g)" fill-rule="evenodd"/>'
    '<linearGradient id="b" x1="-1988.7" x2="-1988.7" y1="-64.368" y2="-51.867" gradientTransform="matrix(12.44 0 0 12.44 25210 1133.3)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient>';
  }
}

contract BootcampSVG4 is IExternalStatic {
  function getSVG() external override pure returns (string memory) {
    return '<path d="m414.5 396.5v93.9l110.3-154.7-110.3 60.8z" clip-rule="evenodd" fill="url(#b)" fill-rule="evenodd"/>'
    '<linearGradient id="c" x1="-1997.7" x2="-1997.7" y1="-64.368" y2="-51.867" gradientTransform="matrix(12.44 0 0 12.44 25210 1133.3)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#662d91" offset="1"/></linearGradient>'
    '<path d="m413.8 396.5l-110.6-60.8 110.6 154.7v-93.9z" clip-rule="evenodd" fill="url(#c)" fill-rule="evenodd"/>'
    '<linearGradient id="f" x1="-1833.1" x2="-1833.1" y1="-25.875" y2="-18.975" gradientTransform="matrix(6.93 0 0 6.93 13063 442.98)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient>'
    '<path d="m414.7 269.2l-0.8-1.9-109.1 46 0.8 1.9 109.1-46z" clip-rule="evenodd" fill="url(#f)" fill-rule="evenodd"/>'
    '<linearGradient id="e" x1="-1817.3" x2="-1817.3" y1="-25.875" y2="-18.975" gradientTransform="matrix(6.93 0 0 6.93 13062 442.58)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient><path d="m523.5 313.2l-108.8-46-0.8 2 108.8 45.9 0.8-1.9z" clip-rule="evenodd" fill="url(#e)" fill-rule="evenodd"/><linearGradient id="l" x1="-2001.4" x2="-2010.7" y1="-78.57" y2="-69.17" gradientTransform="matrix(13.26 0 0 13.26 27013 1233.4)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#c15dd4" offset=".4"/><stop stop-color="#662d91" offset="1"/></linearGradient>';
  }
}

contract BootcampSVG5 is IExternalStatic {
  function getSVG() external pure returns (string memory) {
    return '<path d="M413.2,129.6h2V376h-2V129.6z" fill="url(#l)"/><linearGradient id="k" x1="-1933.6" x2="-1933.6" y1="-40.994" y2="-31.293" gradientTransform="matrix(9.71 0 0 9.71 19189 789.76)" gradientUnits="userSpaceOnUse"><stop stop-color="#5e0076" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient><path d="m413.2 396.7h2v94.2h-2v-94.2z" fill="url(#k)"/><linearGradient id="h" x1="-2038.3" x2="-2038.4" y1="-90.397" y2="-74.592" gradientTransform="matrix(15.81 0 0 15.81 32641 1556.9)" gradientUnits="userSpaceOnUse"><stop stop-color="#9902bf" offset="0"/><stop stop-color="#662d91" offset="1"/></linearGradient><path d="m524.6 314.6l-110.4-187.4-109.9 186.5-0.6 1 110.5 62.4 110.4-62.5zm-110.4-183.2l107.5 182.5-107.5 60.8-107.5-60.8 107.5-182.5z" clip-rule="evenodd" fill="url(#h)" fill-rule="evenodd"/><linearGradient id="j" x1="-1997.2" x2="-1997.2" y1="-65.657" y2="-52.958" gradientTransform="matrix(12.66 0 0 12.66 25698 1163.4)" gradientUnits="userSpaceOnUse"><stop stop-color="#770195" offset="0"/><stop stop-color="#512374" offset="1"/></linearGradient>'
    '<path d="m414.2 492.8l114.1-160.2-114.1 63-114.5-63 113.6 159 0.9 1.2zm0-94.9l107-59-107 150.1-107.5-150.1 107.5 59z" clip-rule="evenodd" fill="url(#j)" fill-rule="evenodd"/>'
    '<text class="st17 st18 st19 st20" transform="translate(168 75)">CERTIFICATE OF PROFICIENCY</text><text class="st21 st18 st19 st20" transform="translate(130 569)">ETHEREUM DEVELOPER PROGRAM</text><text class="st21 st18 st19 st22" transform="translate(188 613)">ONLINE BOOTCAMP 2021</text><text class="st18 st23" transform="translate(335 655)">ISSUED JAN 2022</text></svg>';
  }
}

contract BootcampNFTCert is ERC721URIStorage {
  uint256 public tokenCounter;
  
  event CreatedBootcampNFT(uint indexed tokenId);
  address public owner;
  // IExternalStatic public baseSVG1;
  // IExternalStatic public baseSVG2;
  BootcampSVG1 public BootcampSVG1_ref;
  BootcampSVG2 public BootcampSVG2_ref;
  BootcampSVG3 public BootcampSVG3_ref;
  BootcampSVG4 public BootcampSVG4_ref;
  BootcampSVG5 public BootcampSVG5_ref;

  constructor(BootcampSVG1 _addrBootcampSVG1, BootcampSVG2 _addrBootcampSVG2, BootcampSVG3 _addrBootcampSVG3, BootcampSVG4 _addrBootcampSVG4, BootcampSVG5 _addrBootcampSVG5) ERC721 ("BOOTCAMP2021", "EDU-DAO0x0") public {
    // studentList = _studentList;
    tokenCounter = 0;
    owner = msg.sender;
    // baseSVG1 = IExternalStatic(new BootcampSVG1());
    // baseSVG2 = IExternalStatic(new BootcampSVG2());
    BootcampSVG1_ref = _addrBootcampSVG1;
    BootcampSVG2_ref = _addrBootcampSVG2;
    BootcampSVG3_ref = _addrBootcampSVG3;
    BootcampSVG4_ref = _addrBootcampSVG4;
    BootcampSVG5_ref = _addrBootcampSVG5;



  }

  modifier onlyOwner {
    require(msg.sender == owner, "Caller is not contract owner");
    _;
 }

  function _baseURI() internal override view virtual returns (string memory) {

    string memory baseURL = "data:image/svg+xml;base64,";  
    string memory svgBase64Encoded = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            BootcampSVG1_ref.getSVG(),
            BootcampSVG2_ref.getSVG(),
            BootcampSVG3_ref.getSVG(),
            BootcampSVG4_ref.getSVG(),
            BootcampSVG5_ref.getSVG())
            
        )
      )
    );
    string memory imageURI = string(abi.encodePacked(baseURL,svgBase64Encoded));

  return string(
    abi.encodePacked(
      "data:application/json;base64,",
      Base64.encode(
        bytes(
          abi.encodePacked(
              '{"name":"',
              "2021 ConsenSys Academy Bootcamp Certificate",
              '", "description":"On-Chain Bootcamp Certification", "attributes":"", "image":"',imageURI,'"}'
          )
        )
      )
    )
  );

}

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
  }

  function create(address _student) public onlyOwner {
    
    _safeMint(_student, tokenCounter);
    tokenCounter = tokenCounter + 1;

    emit CreatedBootcampNFT(tokenCounter);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
) public virtual override onlyOwner {

    _transfer(from, to, tokenId);
}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
) public virtual override onlyOwner {
    safeTransferFrom(from, to, tokenId, "");
}

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override onlyOwner {

    _safeTransfer(from, to, tokenId, _data);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
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

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overriden in child contracts.
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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