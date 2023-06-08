// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

library NFTRenderer {
    struct RenderParams {
        address pool;
        uint256 id;
        string tokenSymbol;
        string nftSymbol;
        address tokenAddress;
        address nftAddress;
        uint256 swapFee;
        uint256 poolShare;
        address owner;
    }

    function render(RenderParams memory params) public pure returns (string memory) {
        string memory image = string.concat(
            '<svg width="800" height="1066" viewBox="0 0 800 1066" fill="none" xmlns="http://www.w3.org/2000/svg" >',
            '<style> .text-quantico { font-family: "Quantico"; font-weight: bold; } .text-lg { font-size: 48px; } .text-md { font-size: 32px; } .text-sm { font-size: 24px; } </style>',
            '<defs> <style type="text/css"> @import url("https://fonts.googleapis.com/css?family=Quantico:400,100,100italic,300,300italic,400italic,500,500italic,700,700italic,900,900italic"); </style> </defs>',
            renderForeground(),
            renderSnow(),
            renderCurve(),
            renderContent(params),
            renderBackground(),
            '</svg>'
        );

        string memory json = string.concat(
            '{"name":"',
            renderName(params.poolShare, params.tokenSymbol, params.nftSymbol),
            '",',
            '"description":"',
            renderDescription(params),
            '",',
            '"image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(image)),
            '",',
            '"attributes": ',
            renderAttributes(params),
            '}'
        );

        return string.concat('data:application/json;base64,', Base64.encode(bytes(json)));
    }

    function renderName(
        uint256 poolShare,
        string memory tokenSymbol,
        string memory nftSymbol
    ) internal pure returns (string memory name) {
        name = string.concat(
            'SeaCows Position V1 - ',
            convertToFloatString(poolShare),
            '% - ',
            nftSymbol,
            '/',
            tokenSymbol
        );
    }

    function renderForeground() internal pure returns (string memory foreground) {
        foreground = string.concat(
            '<g clip-path="url(#clip0_4414_291095)">',
            renderForeground1(),
            renderForeground2(),
            // renderForeground3(),
            '</g>'
        );
    }

    function renderForeground1() internal pure returns (string memory foreground1) {
        foreground1 = string.concat(
            '<rect width="800" height="1066" rx="16" fill="url(#paint0_linear_4414_291095)" /> <rect width="800" height="1066" rx="16" fill="url(#paint1_linear_4414_291095)" /> <rect width="800" height="1066" rx="16" fill="url(#paint2_linear_4414_291095)" />',
            '<path d="M306.5 1261C807.146 1261 1213 855.146 1213 354.5C1213 -146.146 807.146 -552 306.5 -552C-194.146 -552 -600 -146.146 -600 354.5C-600 855.146 -194.146 1261 306.5 1261Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.498 1235.41C793.01 1235.41 1187.41 841.01 1187.41 354.498C1187.41 -132.014 793.01 -526.41 306.498 -526.41C-180.014 -526.41 -574.41 -132.014 -574.41 354.498C-574.41 841.01 -180.014 1235.41 306.498 1235.41Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.499 1209.79C778.862 1209.79 1161.79 826.862 1161.79 354.499C1161.79 -117.863 778.862 -500.789 306.499 -500.789C-165.863 -500.789 -548.789 -117.863 -548.789 354.499C-548.789 826.862 -165.863 1209.79 306.499 1209.79Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.501 1184.2C764.73 1184.2 1136.2 812.73 1136.2 354.501C1136.2 -103.728 764.73 -475.195 306.501 -475.195C-151.728 -475.195 -523.195 -103.728 -523.195 354.501C-523.195 812.73 -151.728 1184.2 306.501 1184.2Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.498 1158.58C750.578 1158.58 1110.57 798.58 1110.57 354.5C1110.57 -89.5789 750.578 -449.576 306.498 -449.576C-137.581 -449.576 -497.578 -89.5789 -497.578 354.5C-497.578 798.58 -137.581 1158.58 306.498 1158.58Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.5 1132.98C736.445 1132.98 1084.98 784.445 1084.98 354.5C1084.98 -75.445 736.445 -423.984 306.5 -423.984C-123.445 -423.984 -471.984 -75.445 -471.984 354.5C-471.984 784.445 -123.445 1132.98 306.5 1132.98Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.502 1107.39C722.313 1107.39 1059.39 770.311 1059.39 354.5C1059.39 -61.3112 722.313 -398.393 306.502 -398.393C-109.309 -398.393 -446.391 -61.3112 -446.391 354.5C-446.391 770.311 -109.309 1107.39 306.502 1107.39Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.499 1081.77C708.161 1081.77 1033.77 756.163 1033.77 354.501C1033.77 -47.1604 708.161 -372.771 306.499 -372.771C-95.1623 -372.771 -420.773 -47.1604 -420.773 354.501C-420.773 756.163 -95.1623 1081.77 306.499 1081.77Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />'
        );
    }

    function renderForeground2() internal pure returns (string memory foreground2) {
        foreground2 = string.concat(
            '<path d="M306.501 1056.18C694.029 1056.18 1008.18 742.027 1008.18 354.499C1008.18 -33.0285 694.029 -347.182 306.501 -347.182C-81.0266 -347.182 -395.18 -33.0285 -395.18 354.499C-395.18 742.027 -81.0266 1056.18 306.501 1056.18Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.499 1030.56C679.877 1030.56 982.56 727.877 982.56 354.499C982.56 -18.8797 679.877 -321.562 306.499 -321.562C-66.8797 -321.562 -369.562 -18.8797 -369.562 354.499C-369.562 727.877 -66.8797 1030.56 306.499 1030.56Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.496 1004.97C665.74 1004.97 956.965 713.744 956.965 354.5C956.965 -4.74384 665.74 -295.969 306.496 -295.969C-52.7477 -295.969 -343.973 -4.74384 -343.973 354.5C-343.973 713.744 -52.7477 1004.97 306.496 1004.97Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.502 979.349C651.596 979.349 931.351 699.594 931.351 354.5C931.351 9.40491 651.596 -270.35 306.502 -270.35C-38.5931 -270.35 -318.348 9.40491 -318.348 354.5C-318.348 699.594 -38.5931 979.349 306.502 979.349Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.499 953.757C637.46 953.757 905.757 685.46 905.757 354.499C905.757 23.5388 637.46 -244.758 306.499 -244.758C-24.4612 -244.758 -292.758 23.5388 -292.758 354.499C-292.758 685.46 -24.4612 953.757 306.499 953.757Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.501 928.167C623.328 928.167 880.167 671.328 880.167 354.501C880.167 37.6747 623.328 -219.164 306.501 -219.164C-10.3253 -219.164 -267.164 37.6747 -267.164 354.501C-267.164 671.328 -10.3253 928.167 306.501 928.167Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.503 902.544C609.18 902.544 854.548 657.176 854.548 354.499C854.548 51.8215 609.18 -193.547 306.503 -193.547C3.82541 -193.547 -241.543 51.8215 -241.543 354.499C-241.543 657.176 3.82541 902.544 306.503 902.544Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.5 876.954C595.044 876.954 828.954 643.044 828.954 354.5C828.954 65.9573 595.044 -167.953 306.5 -167.953C17.9573 -167.953 -215.953 65.9573 -215.953 354.5C-215.953 643.044 17.9573 876.954 306.5 876.954Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.502 851.334C580.896 851.334 803.336 628.894 803.336 354.5C803.336 80.1061 580.896 -142.334 306.502 -142.334C32.1081 -142.334 -190.332 80.1061 -190.332 354.5C-190.332 628.894 32.1081 851.334 306.502 851.334Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
            '<path d="M306.5 825.742C566.759 825.742 777.742 614.759 777.742 354.5C777.742 94.24 566.759 -116.742 306.5 -116.742C46.24 -116.742 -164.742 94.24 -164.742 354.5C-164.742 614.759 46.24 825.742 306.5 825.742Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />'
        );
    }

    // function renderForeground3() internal pure returns (string memory foreground3) {
    //     foreground3 = string.concat(
    //         '<path d="M306.497 800.151C552.623 800.151 752.147 600.627 752.147 354.501C752.147 108.376 552.623 -91.1484 306.497 -91.1484C60.3718 -91.1484 -139.152 108.376 -139.152 354.501C-139.152 600.627 60.3718 800.151 306.497 800.151Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.499 774.531C538.475 774.531 726.529 586.477 726.529 354.501C726.529 122.525 538.475 -65.5293 306.499 -65.5293C74.5226 -65.5293 -113.531 122.525 -113.531 354.501C-113.531 586.477 74.5226 774.531 306.499 774.531Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.501 748.939C524.343 748.939 700.939 572.343 700.939 354.501C700.939 136.658 524.343 -39.9375 306.501 -39.9375C88.6585 -39.9375 -87.9375 136.658 -87.9375 354.501C-87.9375 572.343 88.6585 748.939 306.501 748.939Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.502 723.316C510.195 723.316 675.32 558.191 675.32 354.498C675.32 150.805 510.195 -14.3203 306.502 -14.3203C102.809 -14.3203 -62.3164 150.805 -62.3164 354.498C-62.3164 558.191 102.809 723.316 306.502 723.316Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.5 697.726C496.058 697.726 649.726 544.058 649.726 354.5C649.726 164.941 496.058 11.2734 306.5 11.2734C116.941 11.2734 -36.7266 164.941 -36.7266 354.5C-36.7266 544.058 116.941 697.726 306.5 697.726Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.501 672.134C481.926 672.134 624.136 529.924 624.136 354.5C624.136 179.075 481.926 36.8652 306.501 36.8652C131.077 36.8652 -11.1328 179.075 -11.1328 354.5C-11.1328 529.924 131.077 672.134 306.501 672.134Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.499 646.514C467.774 646.514 598.514 515.774 598.514 354.499C598.514 193.224 467.774 62.4844 306.499 62.4844C145.224 62.4844 14.4844 193.224 14.4844 354.499C14.4844 515.774 145.224 646.514 306.499 646.514Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.497 620.923C453.638 620.923 572.919 501.642 572.919 354.501C572.919 207.36 453.638 88.0781 306.497 88.0781C159.356 88.0781 40.0742 207.36 40.0742 354.501C40.0742 501.642 159.356 620.923 306.497 620.923Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.498 595.303C439.49 595.303 547.301 487.492 547.301 354.5C547.301 221.508 439.49 113.697 306.498 113.697C173.506 113.697 65.6953 221.508 65.6953 354.5C65.6953 487.492 173.506 595.303 306.498 595.303Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.5 569.711C425.358 569.711 521.711 473.358 521.711 354.5C521.711 235.642 425.358 139.289 306.5 139.289C187.642 139.289 91.2891 235.642 91.2891 354.5C91.2891 473.358 187.642 569.711 306.5 569.711Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.501 544.092C411.21 544.092 496.092 459.21 496.092 354.501C496.092 249.793 411.21 164.91 306.501 164.91C201.793 164.91 116.91 249.793 116.91 354.501C116.91 459.21 201.793 544.092 306.501 544.092Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.499 518.498C397.073 518.498 470.498 445.073 470.498 354.499C470.498 263.925 397.073 190.5 306.499 190.5C215.925 190.5 142.5 263.925 142.5 354.499C142.5 445.073 215.925 518.498 306.499 518.498Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.501 492.908C382.941 492.908 444.908 430.941 444.908 354.501C444.908 278.061 382.941 216.094 306.501 216.094C230.061 216.094 168.094 278.061 168.094 354.501C168.094 430.941 230.061 492.908 306.501 492.908Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />',
    //         '<path d="M306.502 467.288C368.793 467.288 419.29 416.791 419.29 354.5C419.29 292.21 368.793 241.713 306.502 241.713C244.211 241.713 193.715 292.21 193.715 354.5C193.715 416.791 244.211 467.288 306.502 467.288Z" stroke="white" stroke-opacity="0.1" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />'
    //     );
    // }

    function renderBackground() internal pure returns (string memory background) {
        background = string.concat(
            '<rect x="0.5" y="0.5" width="799" height="1065" rx="15.5" stroke="url(#paint7_linear_4414_291095)" />',
            '<defs> <filter id="filter0_b_4414_291095" x="86.8359" y="20.8359" width="236.547" height="236.547" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB" >',
            '<feFlood flood-opacity="0" result="BackgroundImageFix" /> <feGaussianBlur in="BackgroundImageFix" stdDeviation="45.5" /> <feComposite in2="SourceAlpha" operator="in" result="effect1_backgroundBlur_4414_291095" /> <feBlend mode="normal" in="SourceGraphic" in2="effect1_backgroundBlur_4414_291095" result="shape" /> </filter>',
            '<filter id="filter1_b_4414_291095" x="-27.2422" y="456.77" width="374.816" height="374.807" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB" >',
            '<feFlood flood-opacity="0" result="BackgroundImageFix" /> <feGaussianBlur in="BackgroundImageFix" stdDeviation="45.5" /> <feComposite in2="SourceAlpha" operator="in" result="effect1_backgroundBlur_4414_291095" /> <feBlend mode="normal" in="SourceGraphic" in2="effect1_backgroundBlur_4414_291095" result="shape" /> </filter>',
            '<linearGradient id="paint0_linear_4414_291095" x1="0" y1="533" x2="800" y2="533" gradientUnits="userSpaceOnUse" > <stop stop-color="#BBEF39" /> <stop offset="1" stop-color="#62EE17" /> </linearGradient>',
            '<linearGradient id="paint1_linear_4414_291095" x1="0" y1="533" x2="800" y2="533" gradientUnits="userSpaceOnUse" > <stop stop-color="#00FF87" /> <stop offset="1" stop-color="#60EFFF" /> </linearGradient>',
            '<linearGradient id="paint2_linear_4414_291095" x1="0" y1="0" x2="800" y2="1066" gradientUnits="userSpaceOnUse" > <stop stop-color="#1FA2FF" /> <stop offset="0.5" stop-color="#12D8FA" /> <stop offset="1" stop-color="#A6FFCB" /> </linearGradient>',
            '<linearGradient id="paint3_linear_4414_291095" x1="218.695" y1="115.583" x2="191.528" y2="162.637" gradientUnits="userSpaceOnUse" > <stop stop-color="white" /> <stop offset="1" stop-color="white" stop-opacity="0" /> </linearGradient>',
            '<linearGradient id="paint4_linear_4414_291095" x1="208.184" y1="561.013" x2="112.158" y2="727.334" gradientUnits="userSpaceOnUse" > <stop stop-color="white" /> <stop offset="1" stop-color="white" stop-opacity="0" /> </linearGradient>',
            '<linearGradient id="paint5_linear_4414_291095" x1="347" y1="301" x2="771.331" y2="782.156" gradientUnits="userSpaceOnUse" > <stop stop-color="white" stop-opacity="0.3" /> <stop offset="1" stop-color="white" stop-opacity="0" /> </linearGradient>',
            '<linearGradient id="paint6_linear_4414_291095" x1="532.5" y1="301" x2="532.5" y2="684" gradientUnits="userSpaceOnUse" > <stop stop-color="white" /> <stop offset="1" stop-color="white" stop-opacity="0.29" /> </linearGradient>',
            '<linearGradient id="paint7_linear_4414_291095" x1="-4.47205e-06" y1="224.5" x2="800" y2="829" gradientUnits="userSpaceOnUse" >',
            '<stop stop-color="#FFFFFE" stop-opacity="0.42" /> <stop offset="0.25" stop-color="white" stop-opacity="0.77" /> <stop offset="0.5" stop-color="white" stop-opacity="0" /> <stop offset="0.75" stop-color="white" stop-opacity="0.42" /> <stop offset="1" stop-color="white" stop-opacity="0.7" /> </linearGradient>',
            '<clipPath id="clip0_4414_291095"> <rect width="800" height="1066" rx="16" fill="white" /> </clipPath> </defs>'
        );
    }

    function renderContent(RenderParams memory params) internal pure returns (string memory content) {
        content = string.concat(
            renderPoolAddress(params.pool),
            renderId(params.id),
            renderSymbol(params.tokenSymbol, params.nftSymbol),
            renderSwapFee(params.swapFee),
            renderPoolShare(params.poolShare),
            renderOwnerAddress(params.owner)
        );
    }

    function renderPoolAddress(address _pool) internal pure returns (string memory pool) {
        pool = string.concat(
            '<text x="41.36" y="57" fill="black" class="text-quantico text-sm">',
            'POOL: ',
            Strings.toHexString(_pool),
            '</text>'
        );
    }

    function renderOwnerAddress(address _owner) internal pure returns (string memory owner) {
        owner = string.concat(
            '<text x="50.08" y="1020.01" fill="black" class="text-quantico text-sm">',
            'Owner: ',
            Strings.toHexString(_owner),
            '</text>'
        );
    }

    function renderCurve() internal pure returns (string memory curve) {
        curve = string.concat(
            '<path d="M347 301V313.289C347 518.027 513.102 684 718 684" stroke="url(#paint5_linear_4414_291095)" stroke-width="79" stroke-linecap="round" />',
            '<path d="M320.333 301C320.333 315.728 332.272 327.667 347 327.667C361.728 327.667 373.667 315.728 373.667 301C373.667 286.272 361.728 274.333 347 274.333C332.272 274.333 320.333 286.272 320.333 301ZM691.333 684C691.333 698.728 703.272 710.667 718 710.667C732.728 710.667 744.667 698.728 744.667 684C744.667 669.272 732.728 657.333 718 657.333C703.272 657.333 691.333 669.272 691.333 684ZM342 301V313H352V301H342ZM342 313C342 520.659 510.341 689 718 689V679C515.864 679 352 515.136 352 313H342Z" fill="url(#paint6_linear_4414_291095)" />'
        );
    }

    function renderSnow() internal pure returns (string memory snow) {
        snow = string.concat(
            '<g filter="url(#filter0_b_4414_291095)"> <path d="M230.638 149.23L215.468 140.472L232.385 135.943L230.315 128.217L213.399 132.746L222.155 117.581L215.235 113.586L206.479 128.751L201.943 111.837L194.218 113.907L198.753 130.822L183.584 122.064L179.585 128.99L194.755 137.748L177.835 142.282L179.908 150.003L196.824 145.474L188.068 160.639L194.988 164.634L203.744 149.469L208.28 166.383L216.002 164.318L211.47 147.398L226.639 156.156L230.638 149.23Z" fill="url(#paint3_linear_4414_291095)" fill-opacity="0.6" /> </g>',
            '<g filter="url(#filter1_b_4414_291095)"> <path d="M250.399 679.945L196.78 648.988L256.574 632.979L249.258 605.67L189.464 621.679L220.414 568.074L195.954 553.952L165.005 607.558L148.972 547.77L121.664 555.089L137.697 614.876L84.0781 583.919L69.9434 608.401L123.562 639.358L63.7574 655.387L71.0843 682.676L130.878 666.667L99.9287 720.273L124.388 734.394L155.338 680.789L171.37 740.576L198.667 733.277L182.645 673.47L236.264 704.427L250.399 679.945Z" fill="url(#paint4_linear_4414_291095)" fill-opacity="0.6" /> </g>'
        );
    }

    function renderId(uint256 _id) internal pure returns (string memory id) {
        id = string.concat(
            '<text x="681.378" y="158.72" fill="black" class="text-quantico text-md">',
            '#',
            Strings.toString(_id),
            '</text>'
        );
    }

    function renderSymbol(
        string memory tokenSymbol,
        string memory nftSymbol
    ) internal pure returns (string memory symbol) {
        symbol = string.concat(
            '<text x="516.632" y="200.4" fill="black" class="text-quantico text-lg">',
            nftSymbol,
            '/',
            tokenSymbol,
            '</text>'
        );
    }

    function renderPoolShare(uint256 _poolShare) internal pure returns (string memory poolShare) {
        poolShare = string.concat(
            '<text x="260.08" y="874" fill="black" class="text-quantico text-lg">',
            'Pool Share: ',
            convertToFloatString(_poolShare),
            '%',
            '</text>'
        );
    }

    function renderSwapFee(uint256 _swapFee) internal pure returns (string memory swapFee) {
        swapFee = string.concat(
            '<text x="346.08" y="803.96" fill="black" class="text-quantico text-lg">',
            'Swap Fee: ',
            convertToFloatString(_swapFee),
            '%',
            '</text>'
        );
    }

    function renderDescription(RenderParams memory params) internal pure returns (string memory description) {
        description = string.concat(
            'This NFT represents a liquidity position in a Seacows V1 ',
            params.nftSymbol,
            '/',
            params.tokenSymbol,
            ' pool. The owner of this NFT can modify or redeem the position.\n\nPool Address: ',
            Strings.toHexString(params.pool),
            '\n',
            params.nftSymbol,
            ' Address: ',
            Strings.toHexString(params.nftAddress),
            '\n',
            params.tokenSymbol,
            ' Address: ',
            Strings.toHexString(params.tokenAddress),
            '\nFee Tier: ',
            convertToFloatString(params.swapFee),
            '%\nToken ID: ',
            Strings.toString(params.id),
            '\n\nDISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated'
        );
    }

    function renderAttributes(RenderParams memory params) internal pure returns (string memory attributes) {
        attributes = string.concat(
            '[{',
            '"trait_type": "ERC20","value": "',
            params.tokenSymbol,
            '"},{"trait_type": "ERC721", "value": "',
            params.nftSymbol,
            '"},{"trait_type": "Fee Tier", "value": "',
            convertToFloatString(params.swapFee),
            '"}]'
        );
    }

    function convertToFloatString(uint256 value) internal pure returns (string memory) {
        uint256 precision = 10 ** 4;
        uint256 quotient = value / precision;
        uint256 remainderRaw = value % precision;

        string memory fractionalPart;

        if (remainderRaw != 0) {
            // remove trailing zeros
            uint256 remainder = remainderRaw;
            while (remainder != 0 && remainder % 10 == 0) {
                remainder = remainder / 10;
            }
            fractionalPart = Strings.toString(remainder);
            // Pad fractional part with zeros if needed
            uint256 fractionalPartLength = bytes(Strings.toString(remainderRaw)).length;
            for (uint256 i = fractionalPartLength; i < 4; i++) {
                fractionalPart = string.concat('0', fractionalPart);
            }

            fractionalPart = string.concat('.', fractionalPart);
        }

        return string.concat(Strings.toString(quotient), fractionalPart);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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