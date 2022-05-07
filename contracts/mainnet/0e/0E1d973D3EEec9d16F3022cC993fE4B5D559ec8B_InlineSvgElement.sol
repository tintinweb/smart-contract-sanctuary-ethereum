//	SPDX-License-Identifier: MIT
/// @notice A helper to create svg elements
pragma solidity ^0.8.0;


library InlineSvgElement {
  function getTspanBytes1(
      string memory class,
      string memory display, 
      string memory dx, 
      string memory dy, 
      bytes1 val)
      public pure 
      returns (string memory) {
    return string(abi.encodePacked('<tspan class="', class, '" display="', display, '" dx="', dx, '" dy="', dy, '" >', val));
  }

  function getAnimate(
      string memory attributeName,
      string memory values,
      string memory duration,
      string memory begin,
      string memory repeatCount,
      string memory fill) 
      public pure 
      returns (string memory) {
    return string(abi.encodePacked('<animate attributeName="', attributeName, '" values="', values, '" dur="', duration, 'ms" begin="', begin, 'ms" repeatCount="', repeatCount, '"  fill="', fill, '" />'));
  }
}