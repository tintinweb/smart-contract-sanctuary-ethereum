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
            return '<rect x="562.108" y="216.178" width="44.5534" height="87.0347" transform="rotate(157.535 562.108 216.178)" fill="#DDDDDD"/><rect width="44.5534" height="87.0347" transform="matrix(0.84372 0.536783 0.536783 -0.84372 157.979 180.82)" fill="#DDDDDD"/><rect width="44.5534" height="87.0347" transform="matrix(0.84372 0.536783 0.536783 -0.84372 442.479 685.746)" fill="#DDDDDD"/><rect x="191.113" y="663.754" width="44.5534" height="87.0347" transform="rotate(157.535 191.113 663.754)" fill="#DDDDDD"/><rect x="76.0637" y="418.342" width="45" height="81" transform="rotate(-175 76.0637 418.342)" fill="#DDDDDD"/><rect x="439.579" y="795.459" width="73" height="130" transform="rotate(-175 439.579 795.459)" fill="#AAAAAA"/><rect x="251.298" y="778.988" width="73" height="130" transform="rotate(-175 251.298 778.988)" fill="#AAAAAA"/><rect x="492.881" y="174.744" width="73" height="130" transform="rotate(-175 492.881 174.744)" fill="#AAAAAA"/><rect x="304.6" y="158.271" width="73" height="130" transform="rotate(-175 304.6 158.271)" fill="#AAAAAA"/><rect x="369.198" y="785.287" width="119" height="116" transform="rotate(-175 369.198 785.287)" fill="#DDDDDD"/><rect x="423.022" y="158.594" width="119" height="116" transform="rotate(-175 423.022 158.594)" fill="#DDDDDD"/><circle cx="340.939" cy="408.39" r="262" transform="rotate(-175 340.939 408.39)" fill="#DDDDDD" stroke="black" stroke-width="28"/><circle cx="340.939" cy="408.39" r="216" transform="rotate(-175 340.939 408.39)" fill="#F6F5F6" stroke="black" stroke-width="28"/><line x1="556.978" y1="556.623" x2="487.944" y2="703.164" stroke="black" stroke-width="28"/><line x1="496.142" y1="695.815" x2="442.336" y2="714.195" stroke="black" stroke-width="28"/><line y1="-14" x2="161.988" y2="-14" transform="matrix(0.262608 0.964903 0.964903 -0.262608 115.95 513.18)" stroke="black" stroke-width="28"/><line y1="-14" x2="56.8595" y2="-14" transform="matrix(0.8758 0.482674 0.482674 -0.8758 144.941 652.236)" stroke="black" stroke-width="28"/><line x1="452.91" y1="642.828" x2="430" y2="801.434" stroke="black" stroke-width="28"/><line y1="-14" x2="160" y2="-14" transform="matrix(-0.0360215 0.999351 0.999351 0.0360215 203.74 620.449)" stroke="black" stroke-width="28"/><line x1="368.326" y1="795.249" x2="379.744" y2="664.747" stroke="black" stroke-width="28"/><line x1="243.802" y1="784.356" x2="255.655" y2="648.874" stroke="black" stroke-width="28"/><line x1="445.083" y1="789.919" x2="171.13" y2="765.952" stroke="black" stroke-width="28"/><line x1="248.919" y1="691.447" x2="194.128" y2="686.653" stroke="black" stroke-width="28"/><line x1="440.189" y1="708.181" x2="385.398" y2="703.388" stroke="black" stroke-width="28"/><line x1="371.085" y1="740.787" x2="256.519" y2="730.763" stroke="black" stroke-width="28"/><line y1="-14" x2="161.988" y2="-14" transform="matrix(-0.262608 -0.964903 -0.964903 0.262608 565.928 303.605)" stroke="black" stroke-width="28"/><line y1="-14" x2="56.8595" y2="-14" transform="matrix(-0.8758 -0.482674 -0.482674 0.8758 536.937 164.549)" stroke="black" stroke-width="28"/><line x1="124.899" y1="260.163" x2="193.934" y2="113.622" stroke="black" stroke-width="28"/><line x1="185.736" y1="120.97" x2="239.542" y2="102.59" stroke="black" stroke-width="28"/><line y1="-14" x2="160.253" y2="-14" transform="matrix(0.0310707 -0.999517 -0.999517 -0.0310707 477.925 196.527)" stroke="black" stroke-width="28"/><line x1="228.782" y1="173.8" x2="250.872" y2="15.3318" stroke="black" stroke-width="28"/><line y1="-14" x2="131" y2="-14" transform="matrix(-0.0871557 0.996195 0.996195 0.0871557 449.034 33.3887)" stroke="black" stroke-width="28"/><line y1="-14" x2="136" y2="-14" transform="matrix(-0.0871557 0.996195 0.996195 0.0871557 324.51 22.4941)" stroke="black" stroke-width="28"/><line y1="-14" x2="275" y2="-14" transform="matrix(-0.996195 -0.0871557 -0.0871557 0.996195 508.532 64.6934)" stroke="black" stroke-width="28"/><line y1="-14" x2="55" y2="-14" transform="matrix(-0.996195 -0.0871557 -0.0871557 0.996195 298.249 127.605)" stroke="black" stroke-width="28"/><line y1="-14" x2="55" y2="-14" transform="matrix(-0.996195 -0.0871557 -0.0871557 0.996195 489.518 144.34)" stroke="black" stroke-width="28"/><line y1="-14" x2="115.004" y2="-14" transform="matrix(-0.996195 -0.0871557 -0.0871557 0.996195 427.127 100.23)" stroke="black" stroke-width="28"/><path fill-rule="evenodd" clip-rule="evenodd" d="M335.161 532.357L326.1 531.564L311.985 591.061L338.729 593.4L335.161 532.357Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M330.558 558.054L326.17 557.67L318.925 591.166L331.876 592.299L330.558 558.054Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M272.501 512.143L265.106 506.847L222.661 550.863L244.486 566.496L272.501 512.143Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M255.454 531.915L251.873 529.35L228.581 554.489L239.149 562.059L255.454 531.915Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M391.291 522.589L399.484 518.639L433.749 569.284L409.565 580.941L391.291 522.589Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M404.693 544.991L408.661 543.078L427.295 571.84L415.585 577.484L404.693 544.991Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M410.646 295.852L418.029 301.164L460.568 257.238L438.776 241.559L410.646 295.852Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M427.735 276.117L431.31 278.689L454.656 253.6L444.104 246.008L427.735 276.117Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M291.75 286.452L283.557 290.402L249.292 239.757L273.476 228.1L291.75 286.452Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M278.348 264.05L274.38 265.963L255.746 237.201L267.456 231.557L278.348 264.05Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M444.058 481.126L449.36 473.736L503.69 501.795L488.039 523.607L444.058 481.126Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M466.55 494.378L469.117 490.8L499.248 507.129L491.669 517.691L466.55 494.378Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M215.204 388.382L214.412 397.443L153.368 401.012L155.708 374.268L215.204 388.382Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M189.099 388.454L188.715 392.841L154.47 394.16L155.603 381.209L189.099 388.454Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M468.736 410.563L467.943 419.624L527.439 433.739L529.779 406.994L468.736 410.563Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M494.433 415.166L494.049 419.553L527.545 426.798L528.678 413.848L494.433 415.166Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M455.618 345.197L459.48 353.432L518.024 335.779L506.625 311.473L455.618 345.197Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M480.153 336.281L482.023 340.268L514.631 329.723L509.111 317.953L480.153 336.281Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M240.216 326.755L234.983 334.194L180.394 306.643L195.84 284.686L240.216 326.755Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M217.601 313.714L215.067 317.317L184.786 301.269L192.266 290.637L217.601 313.714Z" fill="#F5F5F6"/><path fill-rule="evenodd" clip-rule="evenodd" d="M227.566 462.186L223.627 453.988L165.25 472.186L176.875 496.385L227.566 462.186Z" fill="#525353"/><path fill-rule="evenodd" clip-rule="evenodd" d="M203.114 471.331L201.207 467.361L168.699 478.21L174.328 489.928L203.114 471.331Z" fill="#F5F5F6"/><rect x="366.11" y="275.577" width="26" height="40" transform="rotate(-175 366.11 275.577)" fill="#DDDEDE" stroke="black" stroke-width="5"/><line x1="83.386" y1="414.968" x2="31.5839" y2="410.436" stroke="black" stroke-width="28"/><line x1="90.2713" y1="336.267" x2="38.4692" y2="331.735" stroke="black" stroke-width="28"/><line x1="34.3461" y1="424.758" x2="43.4621" y2="318.147" stroke="black" stroke-width="28"/>';
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
    enum CaseType { PP, AP, SUB, YACHT, DJ, OP, DD, EXP, VC, GS, TANK, TANK_F, PILOT, AQ, SENATOR }

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