//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWatchScratchersWatchCaseRenderer.sol";


contract AqGsRenderer is IWatchScratchersWatchCaseRenderer {
    constructor() {}

    function renderSvg(
        IWatchScratchersWatchCaseRenderer.CaseType caseType
    ) external pure returns (string memory) {
        if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.AQ) {
            return '<rect transform="rotate(157.54 562.11 216.18)" x="562.11" y="216.18" width="44.553" height="87.035" fill="#ddd"/><rect transform="matrix(.84372 .53678 .53678 -.84372 157.98 180.82)" width="44.553" height="87.035" fill="#ddd"/><rect transform="matrix(.84372 .53678 .53678 -.84372 442.48 685.75)" width="44.553" height="87.035" fill="#ddd"/><rect transform="rotate(157.54 191.11 663.75)" x="191.11" y="663.75" width="44.553" height="87.035" fill="#ddd"/><rect transform="rotate(185 76.064 418.34)" x="76.064" y="418.34" width="45" height="81" fill="#ddd"/><rect transform="rotate(185 439.75 793.47)" x="439.75" y="793.47" width="73" height="128" fill="#aaa"/><rect transform="rotate(185 251.47 777)" x="251.47" y="777" width="73" height="128" fill="#aaa"/><rect transform="rotate(185 492.88 174.74)" x="492.88" y="174.74" width="73" height="126" fill="#aaa"/><rect transform="rotate(185 304.6 158.27)" x="304.6" y="158.27" width="73" height="126" fill="#aaa"/><rect transform="rotate(185 369.37 783.3)" x="369.37" y="783.3" width="119" height="114" fill="#ddd"/><rect transform="rotate(185 423.02 158.59)" x="423.02" y="158.59" width="119" height="112" fill="#ddd"/><circle transform="rotate(185 340.94 408.39)" cx="340.94" cy="408.39" r="262" fill="#ddd" stroke="#000" stroke-width="28"/><circle transform="rotate(185 340.94 408.39)" cx="340.94" cy="408.39" r="216" fill="#272727" stroke="#000" stroke-width="28"/><path d="m335.16 532.36-9.061-0.793-14.115 59.496 26.744 2.34-3.568-61.043z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m330.56 558.06-4.388-0.384-7.245 33.496 12.951 1.133-1.318-34.245z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m272.5 512.14-7.395-5.296-42.445 44.016 21.825 15.633 28.015-54.353z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m255.45 531.92-3.581-2.565-23.293 25.138 10.569 7.571 16.305-30.144z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m391.29 522.59 8.193-3.95 34.265 50.645-24.184 11.657-18.274-58.352z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m404.69 544.99 3.968-1.913 18.634 28.762-11.71 5.644-10.892-32.493z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m410.65 295.85 7.383 5.313 42.539-43.926-21.792-15.679-28.13 54.292z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m427.74 276.12 3.575 2.573 23.346-25.089-10.552-7.592-16.369 30.108z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m291.75 286.45-8.193 3.95-34.265-50.645 24.184-11.657 18.274 58.352z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m278.35 264.05-3.968 1.913-18.634-28.762 11.71-5.644 10.892 32.493z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m444.06 481.13 5.302-7.39 54.33 28.059-15.651 21.812-43.981-42.481z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m466.55 494.38 2.567-3.578 30.131 16.329-7.579 10.562-25.119-23.313z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m215.2 388.38-0.793 9.061-61.043 3.569 2.34-26.744 59.496 14.114z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m189.1 388.46-0.384 4.387-34.245 1.318 1.133-12.95 33.496 7.245z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m468.74 410.56-0.793 9.061 59.496 14.115 2.34-26.745-61.043 3.569z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m494.43 415.17-0.384 4.387 33.496 7.245 1.133-12.95-34.245 1.318z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m455.62 345.2 3.862 8.235 58.544-17.653-11.399-24.306-51.007 33.724z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m480.15 336.28 1.87 3.987 32.608-10.545-5.52-11.77-28.958 18.328z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m240.22 326.76-5.233 7.439-54.589-27.551 15.446-21.957 44.376 42.069z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m217.6 313.72-2.534 3.603-30.281-16.048 7.48-10.632 25.335 23.077z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><path d="m227.57 462.19-3.939-8.198-58.377 18.198 11.625 24.199 50.691-34.199z" clip-rule="evenodd" fill="#C5C5C5" fill-rule="evenodd"/><path d="m203.11 471.33-1.907-3.97-32.508 10.849 5.629 11.718 28.786-18.597z" clip-rule="evenodd" fill="#fff" fill-rule="evenodd"/><rect transform="rotate(185 366.11 275.58)" x="366.11" y="275.58" width="26" height="40" fill="#0B0C0D" stroke="#000" stroke-width="5"/><line x1="83.386" x2="31.584" y1="414.97" y2="410.44" stroke="#000" stroke-width="28"/><line x1="90.271" x2="38.469" y1="336.27" y2="331.74" stroke="#000" stroke-width="28"/><line x1="34.346" x2="43.462" y1="424.76" y2="318.15" stroke="#000" stroke-width="28"/><line x1="556.98" x2="487.94" y1="556.62" y2="703.16" stroke="#000" stroke-width="28"/><line x1="496.14" x2="442.34" y1="695.82" y2="714.2" stroke="#000" stroke-width="28"/><line transform="matrix(.26261 .9649 .9649 -.26261 115.95 513.18)" x2="161.99" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.8758 .48267 .48267 -.8758 144.94 652.24)" x2="56.86" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="452.91" x2="430" y1="642.83" y2="801.43" stroke="#000" stroke-width="28"/><line transform="matrix(-.036022 .99935 .99935 .036022 203.74 620.45)" x2="160" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="368.33" x2="379.74" y1="795.25" y2="664.75" stroke="#000" stroke-width="28"/><line x1="243.8" x2="255.66" y1="784.36" y2="648.87" stroke="#000" stroke-width="28"/><line x1="445.08" x2="171.13" y1="789.92" y2="765.95" stroke="#000" stroke-width="28"/><line x1="248.92" x2="194.13" y1="691.45" y2="686.65" stroke="#000" stroke-width="28"/><line x1="440.19" x2="385.4" y1="708.18" y2="703.39" stroke="#000" stroke-width="28"/><line x1="371.08" x2="256.52" y1="740.79" y2="730.76" stroke="#000" stroke-width="28"/><line transform="matrix(-.26261 -.9649 -.9649 .26261 565.93 303.6)" x2="161.99" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.8758 -.48267 -.48267 .8758 536.94 164.55)" x2="56.86" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="124.9" x2="193.93" y1="260.16" y2="113.62" stroke="#000" stroke-width="28"/><line x1="185.74" x2="239.54" y1="120.97" y2="102.59" stroke="#000" stroke-width="28"/><line transform="matrix(.031071 -.99952 -.99952 -.031071 477.92 196.53)" x2="160.25" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="228.78" x2="250.87" y1="173.8" y2="15.332" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 449.03 33.389)" x2="131" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 324.51 22.494)" x2="136" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 508.53 64.693)" x2="275" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 298.25 127.6)" x2="55" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 489.52 144.34)" x2="55" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 427.13 100.23)" x2="115" y1="-14" y2="-14" stroke="#000" stroke-width="28"/>';
        } else if (caseType == IWatchScratchersWatchCaseRenderer.CaseType.GS) {
            return '<rect transform="rotate(185 418.05 764.83)" x="418.05" y="764.83" width="250" height="719" fill="#D3D2CC"/><rect transform="rotate(194.59 473.92 691.42)" x="473.92" y="691.42" width="38.335" height="94.476" fill="#D3D2CC"/><rect transform="matrix(-.99679 .080016 .080016 .99679 523.12 129.03)" width="38.335" height="94.476" fill="#D3D2CC"/><rect transform="rotate(194.59 192.68 200.04)" x="192.68" y="200.04" width="38.335" height="94.476" fill="#D3D2CC"/><rect transform="matrix(.99679 -.080016 -.080016 -.99679 130.43 658.36)" width="38.335" height="94.476" fill="#D3D2CC"/><rect transform="rotate(185 76.137 404.66)" x="76.137" y="404.66" width="42" height="61" fill="#D3D2CC"/><circle transform="rotate(185 326.44 394.94)" cx="326.44" cy="394.94" r="247.5" fill="#D3D2CC" stroke="#000" stroke-width="28"/><circle transform="rotate(185 326.44 394.94)" cx="326.44" cy="394.94" r="203.5" fill="#F7F8F9" stroke="#000" stroke-width="28"/><line x1="537.81" x2="464.17" y1="523.74" y2="694.83" stroke="#000" stroke-width="28"/><line x1="474.08" x2="422.96" y1="686.83" y2="697.41" stroke="#000" stroke-width="28"/><line x1="433.85" x2="416.13" y1="686.47" y2="774.26" stroke="#000" stroke-width="28"/><line transform="matrix(.024621 .9997 .9997 -.024621 185.02 663.13)" x2="89.56" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.22985 .97323 .97323 -.22985 109.54 481.86)" x2="186.26" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(.92914 .36974 .36974 -.92914 135.53 643.75)" x2="52.202" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="429.32" x2="160.26" y1="762.78" y2="740.27" stroke="#000" stroke-width="28"/><line x1="433.82" x2="440.84" y1="687.7" y2="619.06" stroke="#000" stroke-width="28"/><line x1="169.82" x2="176.85" y1="664.61" y2="595.97" stroke="#000" stroke-width="28"/><line x1="429.22" x2="362.47" y1="694.54" y2="688.7" stroke="#000" stroke-width="28"/><line x1="242.93" x2="176.18" y1="678.24" y2="672.4" stroke="#000" stroke-width="28"/><line x1="353.59" x2="364.23" y1="767.22" y2="645.68" stroke="#000" stroke-width="28"/><line x1="234.87" x2="245.5" y1="758.84" y2="637.31" stroke="#000" stroke-width="28"/><line x1="350.54" x2="244.95" y1="721.78" y2="712.54" stroke="#000" stroke-width="28"/><line transform="matrix(-.22985 -.97323 -.97323 .22985 543.34 308.01)" x2="186.26" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.92914 -.36974 -.36974 .92914 517.35 146.13)" x2="52.202" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.024621 -.9997 -.9997 .024621 468.85 126.83)" x2="89.56" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line x1="220.02" x2="237.74" y1="103.49" y2="15.701" stroke="#000" stroke-width="28"/><line x1="115.07" x2="188.7" y1="266.13" y2="95.049" stroke="#000" stroke-width="28"/><line x1="178.79" x2="229.91" y1="103.05" y2="92.464" stroke="#000" stroke-width="28"/><line transform="matrix(-.99586 -.090935 -.090935 .99586 490.36 64.492)" x2="270" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.072498 .99737 .99737 .072498 496.99 126.28)" x2="69" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.072498 .99737 .99737 .072498 233 103.18)" x2="69" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 478.46 131.69)" x2="67" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 292.17 115.39)" x2="67" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 431.77 34.246)" x2="122" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.087156 .9962 .9962 .087156 313.4 21.883)" x2="122" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><line transform="matrix(-.9962 -.087156 -.087156 .9962 405.71 91.191)" x2="106" y1="-14" y2="-14" stroke="#000" stroke-width="28"/><mask id="c" fill="white"><path d="m507.33 421.3 1.743-19.924-54.149-0.653-0.998 11.408 53.404 9.169z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m507.33 421.3 1.743-19.924-54.149-0.653-0.998 11.408 53.404 9.169z" clip-rule="evenodd" fill="#9A9998" fill-rule="evenodd"/><path d="m509.07 401.38 0.036-3 3.234 0.039-0.282 3.222-2.988-0.261zm-1.743 19.924 2.988 0.262-0.284 3.246-3.212-0.551 0.508-2.957zm-52.406-20.577-2.989-0.262 0.243-2.772 2.782 0.034-0.036 3zm-0.998 11.408-0.508 2.957-2.722-0.467 0.241-2.751 2.989 0.261zm58.135-10.494-1.743 19.925-5.977-0.523 1.743-19.925 5.977 0.523zm-57.101-3.914 54.149 0.653-0.072 6-54.15-0.654 0.073-5.999zm-4.023 14.147 0.998-11.409 5.977 0.523-0.998 11.409-5.977-0.523zm55.885 12.387-53.404-9.169 1.015-5.914 53.404 9.169-1.015 5.914z" fill="#B1B0AF" mask="url(#c)"/><mask id="b" fill="white"><path d="m300.07 575.83 19.924 1.743 0.653-54.149-11.408-0.998-9.169 53.404z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m300.07 575.83 19.924 1.743 0.653-54.149-11.408-0.998-9.169 53.404z" clip-rule="evenodd" fill="#9A9998" fill-rule="evenodd"/><path d="m320 577.57 3 0.036-0.039 3.235-3.222-0.282 0.261-2.989zm-19.924-1.743-0.262 2.989-3.246-0.284 0.551-3.212 2.957 0.507zm20.577-52.406 0.262-2.988 2.772 0.242-0.034 2.782-3-0.036zm-11.408-0.998-2.957-0.508 0.467-2.721 2.751 0.24-0.261 2.989zm10.494 58.136-19.925-1.743 0.523-5.977 19.925 1.743-0.523 5.977zm3.914-57.102-0.653 54.149-6-0.072 0.654-54.149 5.999 0.072zm-14.147-4.023 11.409 0.999-0.523 5.977-11.409-0.998 0.523-5.978zm-12.387 55.886 9.169-53.405 5.914 1.016-9.169 53.404-5.914-1.015z" fill="#B1B0AF" mask="url(#b)"/><mask id="a" fill="white"><path d="m331.8 213.21 19.924 1.743-8.76 53.44-11.408-0.998 0.244-54.185z" clip-rule="evenodd" fill-rule="evenodd"/></mask><path d="m331.8 213.21 19.924 1.743-8.76 53.44-11.408-0.998 0.244-54.185z" clip-rule="evenodd" fill="#9A9998" fill-rule="evenodd"/><path d="m351.72 214.96 2.96 0.485 0.523-3.192-3.222-0.282-0.261 2.989zm-19.924-1.743 0.261-2.989-3.247-0.284-0.014 3.259 3 0.014zm11.164 55.183-0.261 2.989 2.772 0.242 0.45-2.746-2.961-0.485zm-11.408-0.998-3-0.014-0.013 2.762 2.751 0.24 0.262-2.988zm20.429-55.431-19.924-1.743-0.523 5.977 19.924 1.744 0.523-5.978zm-6.06 56.914 8.759-53.44-5.921-0.97-8.759 53.44 5.921 0.97zm-14.631 1.505 11.409 0.999 0.523-5.978-11.409-0.998-0.523 5.977zm-2.494-57.187-0.244 54.185 6 0.027 0.244-54.185-6-0.027z" fill="#B1B0AF" mask="url(#a)"/><rect transform="rotate(154.55 407.02 557.48)" x="407.02" y="557.48" width="7.7239" height="51.79" fill="#9A9998" stroke="#B1B0AF" stroke-width="3"/><rect transform="rotate(127.04 476.61 496.3)" x="476.61" y="496.3" width="7.7239" height="51.79" fill="#9A9998" stroke="#B1B0AF" stroke-width="3"/><rect transform="matrix(.45464 .89068 .89068 -.45464 159.32 467.17)" x="2.018" y=".65406" width="7.7239" height="51.79" fill="#9A9998" stroke="#B1B0AF" stroke-width="3"/><rect transform="rotate(-52.958 176.24 292.41)" x="176.24" y="292.41" width="7.7239" height="51.79" fill="#9A9998" stroke="#B1B0AF" stroke-width="3"/><rect transform="matrix(-.45464 -.89068 -.89068 .45464 490.53 318.54)" x="-2.018" y="-.65406" width="7.7239" height="51.79" fill="#9A9998" stroke="#B1B0AF" stroke-width="3"/><rect transform="matrix(-.81461 -.58001 -.58001 .81461 432.55 247.06)" x="-2.0919" y=".35189" width="7.7239" height="51.79" fill="#9A9998" stroke="#B1B0AF" stroke-width="3"/><rect transform="matrix(.81461 .58001 .58001 -.81461 218.36 539.24)" x="2.0919" y="-.35189" width="7.7239" height="51.79" fill="#9A9998" stroke="#B1B0AF" stroke-width="3"/><rect transform="rotate(-25.452 246.86 232.18)" x="246.86" y="232.18" width="7.7239" height="51.79" fill="#9A9998" stroke="#B1B0AF" stroke-width="3"/><rect transform="rotate(185 203.7 403.78)" x="203.7" y="403.78" width="50" height="39" fill="#D3D3D2" stroke="#9A9998" stroke-width="4"/><rect transform="rotate(185 199.16 398.36)" x="199.16" y="398.36" width="40" height="29" fill="#F6FAFA"/><rect transform="rotate(185 356.05 291.63)" x="356.05" y="291.63" width="40" height="6" fill="#F7F8F9"/><path d="m409.36 324.9-42.126 5.349-5.622 64.254" stroke="#E4E6E7"/><path d="m409.24 324.34c0.963 5.211 1.247 10.637 0.762 16.173-2.415 27.611-23.17 49.212-49.213 53.849 0.932 0.126 1.871 0.231 2.816 0.313 33.286 2.912 62.67-22.156 65.63-55.993 0.497-5.674 0.218-11.235-0.746-16.575l-19.249 2.233z" clip-rule="evenodd" fill="#E9EAEA" fill-rule="evenodd"/><line x1="68.168" x2="30.313" y1="403.96" y2="400.65" stroke="#000" stroke-width="28"/><line x1="73.659" x2="35.803" y1="341.2" y2="337.89" stroke="#000" stroke-width="28"/><line x1="28.096" x2="36.027" y1="414.51" y2="323.86" stroke="#000" stroke-width="28"/>';
        } else {
            revert IWatchScratchersWatchCaseRenderer.WrongCaseRendererCalled();
        }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWatchScratchersWatchCaseRenderer {
    enum CaseType { PP, AP, SUB, YACHT, DJ, OP, DD, DD_P, EXP, VC, GS, TANK, TANK_F, PILOT, AQ, SENATOR }

    error WrongCaseRendererCalled();

    function renderSvg(CaseType caseType)
        external
        pure
        returns (string memory);
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