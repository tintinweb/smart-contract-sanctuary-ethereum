// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Face.sol";
import "./Body.sol";

interface ISurround {
    function hasLongHair(uint256 tokenId) external pure returns (bool);
    function metadata(uint256 tokenId) external view returns (string memory);
    function element(uint256 tokenId) external view returns (string memory);
}

/** @title Youts - Surround Metadat contract 
  * @author @ok_0S / weatherlight.eth
  */
contract Surround is Ownable {
    address public faceAddress;
    address public bodyAddress;

    string[19] private accessoryName = [
        '',
        '',
        '',
        '',
        '',
        'Wings',
        'Wings',
        'Wings',
        'Power Pak',
        'Power Pak',
        'Power Pak',
        'Wings',
        'Power Pak',
        'Headphones',
        'Vibes',
        'Devilish',
        'Zap',
        'Hexed',
        ''
    ]; 

    string[19] private hairName = [
        'Flip',
        'Tails',
        'Curly Looking',
        'Curly Top',
        'Wisp',
        'Curly Looking',
        'Curly Top',
        'Wisp',
        'Curly Looking',
        'Curly Top',
        'Wisp',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        ''
    ]; 
    

	/** @dev Initialize metadata contracts  
	  * @param _faceAddress Address of Facce Metadata Contract 
	  * @param _bodyAddress Address of Body Metadata Contract 
	  */ 
    constructor(address _faceAddress, address _bodyAddress)
        Ownable() 
    {
        faceAddress = _faceAddress;
        bodyAddress = _bodyAddress;
    }


	/** @dev Sets the address for the Face Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Face Metadata Contract 
	  */
    function setFaceAddress(address addr) 
        public
        onlyOwner 
    {
        faceAddress = addr;
    }


	/** @dev Sets the address for the Body Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Body Metadata Contract 
	  */
    function setBodyAddress(address addr) 
        public 
        onlyOwner 
    {
        bodyAddress = addr;
    }

	
    /** @dev Internal function that returns true if a Yout has long hair
	  * @param tokenId A token's numeric ID. 
	  */
    function hasLongHair(uint256 tokenId) 
        external 
        view 
        returns (bool)
    {
        return 
            _surroundIndex(tokenId) <= 1;
    }


    /** @dev Internal function that returns the Surround index for this token
      * @notice This function will return a Surround index for ANY token, even some Youts that don't have hair or accessories
	  * @param tokenId A token's numeric ID
	  */
    function _surroundIndex(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        if (IFace(faceAddress).isWeird(tokenId)) {
            return 
                (uint256(keccak256(abi.encodePacked("SURROUND", tokenId))) % 8) + 11;
        } else {
            return
                uint256(keccak256(abi.encodePacked("SURROUND", tokenId))) %  19;
        }    
    }


	/** @dev Renders a JSON string containing metadata for a Yout's Hair and Accessories
	  * @param tokenId A token's numeric ID
	  */
    function metadata(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory traits;

        if (!IBody(bodyAddress).isRobed(tokenId)) {
            uint256 surroundIndex = _surroundIndex(tokenId);
            traits = string(abi.encodePacked(
                '{"trait_type":"Accessory","value":"',bytes(accessoryName[surroundIndex]).length != 0 ? accessoryName[surroundIndex] : 'none', '"},'
                '{"trait_type":"Hair","value":"',bytes(hairName[surroundIndex]).length != 0 ? hairName[surroundIndex] : 'none', '"}'
            ));
        }

        return
            traits;
    }


	/** @dev Renders a SVG element containing a Yout's Hair and Accessories  
	  * @param tokenId A token's numeric ID 
	  */
    function element(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string[3] memory shortHair = [

            // HAIR / CURLY LOOKING
            _path(
                'M166.4 581.6C112 453.1 375.9 493.9 249.2 340.8C225.6 312.3 168.4 298.6 153.6 341.6C138.7 384.6 181.9 405.2 221.766 405.45C308.179 406.088 367.907 359.586 350.694 241.322C344.451 198.43 301.966 158.969 262.542 182.031C223.118 205.093 235.978 264.955 282.9 285.214C373.109 324.162 488.056 297.5 507.302 225.472C515.562 194.557 509.802 141.74 453.975 143.11C398.148 144.481 397.527 206.746 403.115 230.004C426.331 326.638 610.5 364.5 659.491 279.24C685.5 237.938 674.5 193.138 640.711 182.362C574.614 161.282 557.351 219.687 556.494 237.938C550.623 362.958 782.478 379.174 757.222 241.375',
                's2 r'
            ),

            // HAIR / CURLY TOP
            _path(
                'M145 385C164 494 343 435 259 287C237 246 196 250 179 276C159 303 169 350 215 364C301 389 434 339 418 224C412 175 376 151 335 164C293 178 287 230 311 266C363 362 562 300 586 233C598 199 586 152 540 146C494 138 466 179 471 220C476 289 591 354 685 317C719 304 751 259 720 228C692 199 649 220 634 260C573 426 792 438 772 323',
                's2 r'
            ),
            
            // HAIR / WISP
            _path(
                'M432 173C479 220 519 177 487 132C476 116 453 123 453 137C453 150 462 158 477 158C532 158 536 107 484 91',
                's2 r'
            )

        ];

        // ACCESSORY / WINGS
        string memory wings = string(abi.encodePacked(
            _path(
                'M36 998C15 953 54 827 153 825',
                'r'
            ),
            _path(
                'M904 998C924 953 886 827 786 825',
                'r'
            ),
            _path(
                'M955.1 870C930.6 790.4 806.1 694 684.6 804.5'
            ),
            _path(
                'M-15.5 870C9.07657 790.396 133.5 694 255 804.5'
            ),
            _path(
                'M-41.5 818.5C-12.5 731.3 166.5 631 283.5 777.3'
            ),
            _path(
                'M981.2 818.5C952.1 731.3 773.1 631 656.1 777.3'
            )
        ));

        // ACCESSORY / POWER PAK
        string memory powerPak = string(abi.encodePacked(
            '<line x1="215.5" y1="698" x2="215" y2="745"/>',
            '<circle cx="215" cy="692" r="27" class="fB"/>',
            _path(
                "M190.35 781.6C235.29 759.65 288.55 751.8 324.95 749.05C333.5 743.5 341 739.5 347.5 732.5C341 726.5 334.5 723 327.35 718.8C287.6 721.5 225.4 730 173.2 756.637C170.9 757.81 168.94 759.54 167.52 761.7C134.63 811.02 113 891.02 113 955L143 955C143 897.43 162.38 825.62 190.35 781.6Z",
                "fB eO nS"
            ),
            _path(
                "M593 732C595.5 729.5 599.5 726.5 603.5 724.4C615.35 725.35 627.5 726.1 639.2 726.95C654.2 728.05 669.05 729.45 683.7 732.95C689.9 740.9 694.5 749.2 697.9 758.7C700.85 767 703.38 776.52 705.36 786.46C708.39 801.7 710.25 818.71 709.89 834.26C692 812 689 808 676.46 795.05C676.29 794.14 676.12 793.22 675.94 792.32C673.74 781.28 670.97 769.87 665.84 759.78C652.68 757.67 639.29 756 626 756.08C620.5 752.5 596.5 738.5 593 732Z",
                "fB eO nS"
            )
        ));

        string[19] memory combinations = [

            // (LONG) HAIR / FLIP
            string(abi.encodePacked(
                _path(
                    'M363 734L303 777L303 691L363 734Z',
                    'fB nS'
                ),
                _path(
                    'M577 734L637 691L637 777L577 734Z',
                    'fB nS'
                ),
                _path(
                    'M730.8 753C730.8 753 591.9 735.2 686.9 696.134C781.817 657.036 827.929 574.811 827.929 511.813C827.929 468.525 842.08 146.164 470.392 217.177C112.341 148.151 113 468.525 113 511.812C113 574.811 159.113 657.035 254.05 696.134C348.988 735.232 210.092 752.999 210.092 752.999',
                    'r'
                ),
                _path(
                    'M211.2 790C211.2 790 375.5 752.5 280.4 695.095C201.143 647.274 156.377 571.353 156.377 507.234C156.377 463.115 132.301 187.708 468.984 223.137L469.99 223.112C816.79 202.938 786.319 464.264 786.319 508.228C786.319 572.192 741.479 647.776 662.139 695.429C566.82 752.678 731.411 790 731.411 790',
                    'r'
                ),
                _path(
                    'M213.6 827C235.4 817.7 280 791 304.5 776.05C375.719 732.669 374.716 729.957 304.508 691.998C234.3 654.039 200.199 555.075 200.199 513.048C200.199 471.022 183.148 227 464.983 227H471H477.017C758.852 227 741.801 471.022 741.801 513.048C741.801 555.074 707.7 654.039 637.492 691.998C567.284 729.957 566.281 732.669 637.492 776.05C661.957 790.954 706.616 817.724 728.444 827',
                    'r'
                )
            )),

            // (LONG) HAIR / TAILS
            string(abi.encodePacked(
                '<line class="s3 r" x1="704" y1="732" x2="600" y2="732"/>',
                '<line class="s3 r" x1="340" y1="732" x2="235" y2="732"/>',
                _path(
                    'M168 952C189.7 906.8 247.2 807.8 304 773.1C375 729.7 374 731 304 693C234 655 200 552.1 200 510C200 468 189 224 470 224C751 224 740 468 740 510.1C740 552.1 706 655 636 693C566 731 565 729.7 636 773.1C692.8 807.8 750.3 906.8 772 952'
                ),
                _path(
                    'M119 962C144.7 915.1 212.9 812.4 280.3 776.4C364.5 731.4 363.3 728.6 280.3 689.2C197.3 649.9 157 547.2 157 503.7C157 460.1 136.7 207 470 207C803.4 207 783 460.1 783 503.7C783 547.2 742.7 649.9 659.7 689.2C576.6 728.6 575.4 731.4 659.7 776.4C727 812.4 795.3 915.1 821 962'
                ),
                _path(
                    'M876 962H63C92.8 915.1 172 812.4 250.1 776.4C347.8 731.4 346.4 728.6 250.1 689.2C153.8 649.9 107 547.2 107 503.7C107 460.1 83.4 207 470 207C856.7 207 833 460.1 833 503.7C833 547.2 786.2 649.9 689.9 689.2C593.5 728.6 592.2 731.4 689.9 776.4C768 812.4 847.2 915.1 877 962',
                    's3'
                )
            )),
            
            // HAIR
            shortHair[0],
            shortHair[1],
            shortHair[2],
            
            // HAIR + ACCESSORIES
            string(abi.encodePacked(wings, shortHair[0])),
            string(abi.encodePacked(wings, shortHair[1])),
            string(abi.encodePacked(wings, shortHair[2])),
            string(abi.encodePacked(powerPak, shortHair[0])),
            string(abi.encodePacked(powerPak, shortHair[1])),
            string(abi.encodePacked(powerPak, shortHair[2])),
            
            // ACCESSORIES
            wings,
            powerPak,
            
            // ACCESSORY - HEADPHONES
            _path(
                "M152.004 414.75C123.627 419.571 95.991 425.823 95.3108 431.03C90.8247 465.37 92.1981 493.633 92.1981 505.578C92.1981 515.884 194.718 552.5 206.072 552.5C206.072 552.5 205.067 507.911 205.572 479.5C206.077 451.089 212.072 407 212.072 407C205.586 407 178.472 410.253 152.004 414.75ZM152.004 414.75C152.312 177.239 172.88 161.001 470 161.001C767.147 161.001 787.642 177.242 787.946 414.814M787.946 414.814C816.19 419.626 843.584 425.846 844.261 431.03C848.748 465.37 847.374 493.633 847.374 505.578C847.374 515.884 744.855 552.5 733.5 552.5C733.5 552.5 734.505 507.911 734 479.5C733.495 451.089 727.5 407 727.5 407C734.017 407 761.358 410.284 787.946 414.814Z",
				"s3"
			),
            
            // ACCESSORY - VIBES
            string(abi.encodePacked(
                _path(
                    "M-158 454C-158 377.595 -128.748 -163.906 468.5 -150.765M1093 454C1093 377.595 1065.75 -164.042 468.5 -150.901",
                    "s3"
                ),
                _path(
                    "M-51.5273 784.286C10.0195 710.797 3.6025 745.726 -43.3185 664.204C-95.3419 573.818 -84.7645 522.338 -84.7645 454.575C-84.7645 386.812 -60.0675 -93.5654 467.5 -81.9106C994.864 -93.5436 1020.82 385.935 1020.82 453.572C1020.82 521.208 1038.81 574.242 986.803 664.459C939.9 745.829 933.485 710.965 995.008 784.316",
                    "s3"
                ),
                _path(
                    "M72 975C93.8104 926.163 152.56 833.629 198.836 781.604C238.095 737.468 237.088 734.538 198.836 690.766C143.99 628.007 133.666 542.789 133.666 497.37C133.666 451.951 131.804 145.004 465 145.004C803.163 145.004 807.415 451.951 807.415 497.37C807.415 542.789 796.937 628.007 741.273 690.766C702.451 734.538 701.43 737.468 741.273 781.604C788.239 833.629 847.864 926.163 870 975",
                    "s3"
                ),
                _path(
                    "M-24 990C-1.31124 935.881 54.6084 827.012 107.944 775.688C151.925 733.366 150.878 730.119 107.944 675.027C52.4624 603.834 50.5621 517.148 50.5621 466.817C50.5621 416.486 73.2789 60.3823 465 69.0388C856.721 60.3823 886.438 416.37 886.438 466.701C886.438 517.031 884.538 603.718 829.056 674.911C786.122 730.003 785.075 733.25 829.056 775.572C882.392 826.896 938.311 935.765 961 989.884",
                    "s3"
                ),
                _path(
                    "M-127 1034C-85.3969 979.127 -31.2033 851.273 31.2013 776.646C84.5569 712.84 78.9939 743.167 38.3177 672.387C-6.7819 593.911 -11.4966 522.705 -11.4966 463.871C-11.4966 405.037 11.6469 -11.938 469 -1.81886C926.353 -11.938 954.497 405.036 954.497 463.871C954.497 522.705 949.782 593.911 904.682 672.387C864.006 743.167 858.443 712.84 911.799 776.646C974.203 851.273 1028.4 979.127 1070 1034",
                    "s3"
                )
            )),

            // ACCESSORY - DEVILISH
            string(abi.encodePacked(
                _path(
                    "M157 195L183.845 222.45C198.16 237.088 219.86 249.344 243.571 254.694C267.192 260.023 291.57 258.252 312.116 246.681C281.006 266.321 277.006 270.321 259.391 287.247C251.786 286.735 244.275 285.606 236.969 283.958C221.31 280.425 206.238 274.436 192.752 266.672C202.633 307.692 233.31 350.466 245.485 362.377C238.5 379.5 238 381 232.5 398.5C213.27 379.685 160.102 300.627 158.127 233.378L157 195Z",
                    "fB eO nS"
                ),
                _path(
                    "M782.171 195L755.326 222.45C741.011 237.088 719.311 249.344 695.6 254.694C671.98 260.023 647.601 258.252 627.055 246.681C658.166 266.321 662.166 270.321 679.78 287.247C687.385 286.735 694.897 285.606 702.203 283.958C717.861 280.425 732.933 274.436 746.419 266.672C736.538 307.692 706.675 350.466 694.5 362.377C701.485 379.5 701.985 381 707.485 398.5C726.715 379.685 779.069 300.627 781.044 233.378L782.171 195Z",
                    "fB eO nS"
                ),
                _path(
                    "M145.148 777.499C136.864 777.499 130.148 770.784 130.148 762.5L130.147 676.961L218.795 676.961C227.08 676.961 233.795 683.677 233.795 691.961C233.795 700.245 227.08 706.961 218.795 706.961L184.793 706.961L228.724 745.757C231.769 748.445 233.593 752.254 233.779 756.311C233.966 760.369 232.499 764.328 229.714 767.285L180.805 819.21L215.5 854.5L198.5 880.5L149.292 829.927C143.651 824.178 143.558 815 149.08 809.137L197.256 757.991L160.148 725.22L160.148 762.499C160.148 770.783 153.433 777.499 145.148 777.499Z",
                    "fB eO nS"
                )
            )),

            // ACCESSORY - ZAP
            string(abi.encodePacked(
                _path(
                    "M799.9 126L743.2 211.5L726.3 159.8L672.6 244",
                    "mJ"
                ),
                _path(
                    "M465.4 17L481.7 118.3L434.3 91.87L451.9 190.1",
                    "mJ"
                ),
                _path(
                    "M126 146.4L208.9 206.8L156.6 221.4L238.4 278.8",
                    "mJ"
                )
            )),

            // ACCESSORY - HEXED
            string(abi.encodePacked(
                _path(
                    "M1078.9 314.2C1032 217 977.3 123.7 915.3 35.12L895.3 6.7C870.6 -28.4 800.8 -79.1 800.8 -79.12H157.7C157.7 -79.1 87.9 -28.4 63.3 6.74L43.3 35.3C-18.7 123.9 -73.5 217.3 -120.4 314.5"
                ),
                _path(
                    "M0 962C21.5 911.4 77.9 823.3 125.1 761.7C160 716.1 157.2 720.5 125 668C97 620.5 96.2 619 72 568.7L62 547.9C49.7 522.2 43.3 494.1 43.3 465.7C43.3 437.3 49.7 409.2 62 383.502L72 362.7C103.1 298 139.3 235.9 180.4 176.9L193.6 157.9C209.9 134.5 231.3 114.9 256.1 100.7C281 86.5 308.8 77.9 337.4 75.7L360.7 73.8C432.8 68.1 505.2 68.1 577.3 73.8L600.6 75.7C629.2 77.9 657 86.5 681.9 100.7C706.7 114.9 728.1 134.5 744.4 157.9L757.6 176.7C798.7 235.7 834.9 297.8 866 362.5L876 383.2C888.3 408.9 894.7 437 894.7 465.4C894.7 493.9 888.3 522 876 547.6L866 568.46C844.9 612.3 840 623.5 813.5 668C778.2 723.6 771.2 722.1 812.9 761.6C863.5 809.6 916.5 911.4 938 962"
                ),
                _path(
                    "M85 955C106.4 907.9 163.9 818.7 209.2 768.5C247.7 726 241.3 733.3 200.5 669.4C181.3 640.1 164.7 606.7 143 562.3L134.8 544.9C124.6 523 119.4 499.2 119.4 475.1C119.4 451.1 124.6 427.3 134.8 405.6L143 388C168.7 333.2 198.6 280.7 232.4 230.8L243.3 214.7C256.8 194.9 274.4 178.3 294.9 166.3C315.4 154.3 338.3 147 362 145.1L381.1 143.6C440.6 138.7 500.4 138.7 559.9 143.6L579 145.1C602.7 147 625.6 154.3 646.1 166.3C666.6 178.3 684.2 194.9 697.7 214.7L708.6 230.6C742.4 280.5 772.3 333 797.9 387.8L806.2 405.4C816.4 427.1 821.6 450.9 821.6 474.9C821.6 499 816.4 522.7 806.2 544.5L797.9 562.1C780.6 599.2 762.5 636.1 739.7 670.4C695.8 727.8 693.3 726 731.8 768.5C777.1 818.7 834.6 907.9 856 955"
                ),
                _path(
                    "M1003 941C952.8 791.3 866.6 736.9 866.6 708.7C866.6 678 915.1 631.4 935.7 587.9L947.3 563.2C961.7 532.7 969.2 499.4 969.2 465.7C969.2 431.9 961.7 398.6 947.3 368.2L935.7 343.6C899.4 266.8 857.1 193.1 809.3 123.2L793.8 100.8C774.8 73 749.9 49.9 720.848 32.9994C691.827 16.1331 659.434 5.9878 626.032 3.30067L598.914 1.10053C514.776 -5.70018 430.237 -5.70018 346.103 1.10053L318.984 3.30067C285.581 5.9878 253.191 16.1331 224.169 32.9994C195.148 49.8655 170.223 73.0295 151.206 100.807L135.759 123.358C87.8703 193.33 45.6013 267.035 9.35409 343.773L-2.31787 368.474C-16.6995 398.941 -24.1613 432.249 -24.1613 465.981C-24.1613 499.713 -16.6995 533.02 -2.31787 563.487L9.35409 588.189C32.3854 636.949 67.9719 680.291 67.9719 707.698C67.9719 741.305 -39.044 848.596 -73 937.923"
                ),
                _path(
                    "M1125 974.5C1068 804.6 945 719.1 941.5 702.8C941.5 691 978.8 649.1 1002.2 599.7L1015.4 571.7C1031.7 537.1 1040.2 499.3 1040.2 461C1040.2 422.8 1031.7 385 1015.4 350.4L1002.2 322.5C961 235.4 913 151.7 858.6 72.3L841.1 46.9C819.5 15.4 791.2 -10.9 758.3 -30C725.3 -49.2 688.5 -60.7 650.6 -63.7L619.8 -66.2C524.3 -73.9 428.3 -73.9 332.8 -66.2L302 -63.7C264.1 -60.7 227.3 -49.2 194.4 -30C161.4 -10.9 133.1 15.4 111.5 46.9L94 72.5C39.6 152 -8.3 235.6 -49.5 322.7L-62.8 350.7C-79.1 385.3 -87.6 423.1 -87.6 461.4C-87.5 499.7 -79.1 537.5 -62.8 572L-49.5 600.1C-23.3 655.4 -6.9 689.5 -4.8 698.2C-4.8 707.4 -104.4 895.6 -143 997"
                )
            )),

            // NO HAIR + NO ACCESSORY
            ""

        ];

        return 
            string(abi.encodePacked(
                '<g id="s">',
                    combinations[_surroundIndex(tokenId)],
                "</g>"
            ));
    }


	/** @dev Internal drawing helper function that renders a path element
	  * @param d A string containing the path's `d` attribute
	  */
    function _path(string memory d) 
        internal 
        pure 
        returns (string memory) 
    {
        return 
            string(abi.encodePacked(
                '<path d="', d, '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with the provided class attribute
	  * @param d A string containing the path's `d` attribute
	  * @param classNames A string containing the path's `class` attribute
	  */
    function _path(string memory d, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<path class="', classNames, '" d="', d, '"/>'
            ));
    }

}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;
import "./Uint2str.sol";

interface IFace {
    function isWeird(uint256 tokenId) external pure returns (bool);
    function metadata(uint256 tokenId) external view returns (string memory);
    function element(uint256 tokenId) external view returns (string memory);
}

/** @title Youts - Face Metadata contract
  * @author @ok_0S / weatherlight.eth
  */
contract Face {
    using Uint2str for uint16;

    string[25] private humanFaceNames = [
        "Wiggle",
        "Blinker",
        "Grump",
        "I Liek U",
        "Grin",
        "U-On",
        "Stickout",
        "Black Eye",
        "uwu",
        "Browside Down",
        "Ring",
        "Rude Tude",
        "Devious Lick",
        "Uncle",
        "Nounish",
        "Tired Eye",
        "Smarty",
        "Mascara",
        "X'd Out",
        "2Cool",
        "Stoney",
        "Joyful",
        "Funhappy",
        "Straight Talker",
        "Bitey"
    ];

    string[14] private weirdFaceNames = [
        'North Tree', 
        'East Tree', 
        'West Tree', 
        'South Tree', 
        'Center Tree', 
        'U-shape', 
        'O-shape', 
        'Inverted U-shape', 
        'Rotated I-shape', 
        'Aligned', 
        'Four Eyes', 
        'Spiraling', 
        'Cyclops', 
        'Primal'
    ];
    

	/** @dev External wrapper function that returns true if a Yout is Weird
	  * @param tokenId A token's numeric ID. 
	  */
    function isWeird(uint256 tokenId) 
        external 
        pure 
        returns (bool) 
    {
        return
            _isWeird(tokenId);
    }	


    /** @dev Internal function that returns true if a Yout is Weird
	  * @param tokenId A token's numeric ID. 
	  */
    function _isWeird(uint256 tokenId) 
        internal 
        pure 
        returns (bool) 
    {
        return
            uint256(keccak256(abi.encodePacked("WEIRD", tokenId))) % 100 < 7 ? true : false;
    }
    

	/** @dev Renders a JSON string containing metadata for a Yout's face
	  * @param tokenId A token's numeric ID. 
	  */
    function metadata(uint256 tokenId) 
        external
        view 
        returns (string memory) 
    {
        string memory traits;

        bool weirdCheck = _isWeird(tokenId);

        traits = string(abi.encodePacked(
            '{"trait_type":"Origin","value":"', (weirdCheck ? _weirdOrigin(tokenId) : 'Human'), '"},',
            '{"trait_type":"Face","value":"', (weirdCheck ? _weirdFaceName(tokenId) : _humanFaceName(tokenId)),'"}'
        ));

        return
            traits;
    }


	/** @dev Renders a SVG element containing a Yout's face  
	  * @param tokenId A token's numeric ID. 
	  */
    function element(uint256 tokenId) 
        external 
        view 
        returns (string memory) 
    {
        return 
            string(abi.encodePacked(
                '<g id="f" filter="url(#ds)">', this.isWeird(tokenId) ? _weirdFace(tokenId) : _humanFace(tokenId), "</g>"
            ));
    }


    /** @dev Internal function that returns the weird origin associated with the given token ID.
      * @notice This function will return a weird origin for ANY token, even non-Weird Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _weirdOrigin(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 faceRoll = uint256(keccak256(abi.encodePacked("FACE", tokenId))) % weirdFaceNames.length;
        string memory faceOrigin;

        if (faceRoll < 5) {
            faceOrigin = "Spirit";
        } else if (faceRoll > 8) {
            faceOrigin = "Primordial";
        } else {
            faceOrigin = "Alien";
        }

        return
            faceOrigin;
    }


	/** @dev Internal function that returns the weird face name associated with the given token ID.
      * @notice This function will return a weird face name for ANY token, even non-Weird Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _weirdFaceName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            weirdFaceNames[uint256(keccak256(abi.encodePacked("FACE", tokenId))) % weirdFaceNames.length];
    }


	/** @dev Internal function that returns the name of the human face associated with the given token ID.
      * @notice This function will return a name even for ANY token, even non-Human Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _humanFaceName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            humanFaceNames[uint256(keccak256(abi.encodePacked("FACE", tokenId))) % humanFaceNames.length];
    }


	/** @dev Internal function that returns the human face associated with the given token ID.
      * @notice This function will return a face for ANY token, even non-Human Youts. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _humanFace(uint256 tokenId) 
        internal 
        pure 
        returns (string memory) 
    {
        string[25] memory faces = [

            // WIGGLE
            string(abi.encodePacked(
                _eyes([400, 482, 637, 470]),
                _path(
                    'M350 542C358 576 403 582 428 565C453 548 472 541 500 562C529 584 551 578 576 557C601 536 642 545 659 565'
                )
            )),

            // BLINKER
            string(abi.encodePacked(
                _eyes([444, 505, 598, 468]),
                _path(
                    'M605 562C598 591 550 627 489 593'
                ),
                _path(
                    'M451 431C438 421 422 416 401 429'
                ),
                _path(
                    'M611 385C595 381 579 382 564 402'
                )
            )),

            // GRUMP
            string(abi.encodePacked(
                _eyes([630, 452, 439, 472]),
                _path(
                    'M457 578C477 538 584 496 637 571'
                ),
                _path(
                    'M556 455C570 427 644 398 680 450'
                ),
                _path(
                    'M373 478C384 449 455 414 496 462'
                )
            )),

            // I LIEK U
            string(abi.encodePacked(
                _eyes([388, 508, 639, 484]),
                _path(
                    'M580 572C580 587 568 607 536 608C493 609 485 591 484 581'
                )
            )),

            // GRIN
            string(abi.encodePacked(
                _eyes([589, 443, 382, 443]),
                _path(
                    'M398 553C422 595 529 629 573 542'
                ),
                _path(
                    'M449 440C433 410 352 382 314 440'
                ),
                _path(
                    'M649 440C633 410 552 382 514 440'
                )
            )),

            // U-ON
            string(abi.encodePacked(
                _eyes([567, 450, 461, 446]),
                _path(
                    'M555 532C555 554 559 603 514 603C469 603 473 554 473 532'
                )
            )),

            // STICKOUT
            string(abi.encodePacked(
                _eyes([365, 447, 633, 436]),
                _path(
                    'M614 498L402 505',
                    'r'
                ),
                _path(
                    'M585 506C585 529 589 577 544 577C499 577 503 529 503 506',
                    'r'
                )
            )),

            // BLACK EYE
            string(abi.encodePacked(
                _eyes([394, 487, 633, 458]),
                _path(
                    'M438 578C469 617 587 636 622 542'
                ),
                '<circle class="s0" cx="393" cy="486" r="46.5"/>'
            )),

            // UWU
            string(abi.encodePacked(
                _path(
                    'M662 433C667 464 613 502 580 447'
                ),
                _path(
                    'M326 459C327 491 387 518 410 458'
                ),
                _path(
                    'M426 546C452 605 499 571 497 538C499 571 551 598 567 535'
                )
            )),

            // BROWSIDE DOWN
            string(abi.encodePacked(
                _eyes([615, 567, 402, 578]),
                _path(
                    'M402 494C401 370 597 353 598 498'
                ),
                _path(
                    'M458 591C442 614 373 628 349 577'
                ),
                _path(
                    'M559 581C575 603 644 618 668 567'
                )
            )),

            // RING
            string(abi.encodePacked(
                _eyes([624, 462, 438, 458]),
                _path(
                    'M479 439C461 409 382 381 344 439'
                ),
                _path(
                    'M674 448C658 418 577 390 539 448'
                ),
                _path(
                    'M564 502C570 566 484 573 477 511'
                ),
                _path(
                    'M472 632C485 652 548 668 576 629'
                ),
                _path(
                    'M543 557C546 584 509 587 507 561', 
                    's1'
                )
            )),

            // RUDE TUDE
            string(abi.encodePacked(
                _line([600, 388, 400, 388]),
                _line([540, 443, 469, 443]),
                _path(
                    'M420 622C418 541 581 531 582 626'
                ),
                _path(
                    'M649 425C638 441 605 483 562 515'
                ),
                _path(
                    'M439 425C428 441 395 483 352 515'
                ),
                _path(
                    'M673 455C663 470 634 507 596 535', 
                    's3'
                ),
                _path(
                    'M463 455C453 470 424 507 386 535', 
                    's3'
                ),
                _path(
                    'M329 480C336 518 372 542 409 535C446 528 470 492 463 454C456 417 420 393 383 400C346 407 322 443 329 480Z'
                ),
                _path(
                    'M539 481C546 518 582 542 619 535C656 528 680 492 673 455C665 418 630 393 593 401C556 408 532 444 539 481Z'
                )
            )),

            // DEVIOUS LICK
            string(abi.encodePacked(
                _eyes([337, 462, 665, 438]),
                _path(
                    'M401 511C402 572 617 566 616 495'
                ),
                _path(
                    'M585 540C591 562 605 608 562 618C517 628 511 580 506 558'
                )
            )),

            // UNCLE
            string(abi.encodePacked(
                _eyes([622, 487, 396, 490]),
                _path(
                    'M647 455C633 445 617 441 597 455'
                ),
                _path(
                    'M421 455C407 445 391 441 371 455'
                ),
                _path(
                    'M602 574C593 572 551 567 531 568', 
                    's3 r'
                ),
                _path(
                    'M500 568C492 568 449 570 429 574', 
                    's3 r'
                )
            )),

            // NOUNISH
            string(abi.encodePacked(            
                _path(
                    'M358 449L262 449L262 510',
                    's3 mJ'
                ),
                _path(
                    'M431 598C447 600 524 599 566 599'
                ),
                _line(
                    [547, 449, 504, 449],
                    's3'
                ),
                '<rect x="554" y="403" width="125" height="125" class="s3"/>',
                '<rect x="365" y="403" width="125" height="125" class="s3"/>',
                '<rect x="629" y="429" width="25" height="75" class="fB s0"/>',
                '<rect x="440" y="429" width="25" height="75" class="fB s0"/>'
            )),

            // TIRED EYE
            string(abi.encodePacked(
                _eyes([364, 459, 649, 439]),
                _path(
                    'M449 582C492 628 584 616 598 553'
                ),
                _path(
                    'M316 491C333 516 403 520 416 471.102'
                )
            )),

            // SMARTY
            string(abi.encodePacked(
                _eyes([419, 480, 608, 481]),
                _path(
                    'M602 571C586 623 464 629 440 575'
                )
            )),

            // MASCARA
            string(abi.encodePacked(
                _eyes([603, 441, 417, 436]),
                _path(
                    'M681 429C667 419 651 415 631 429'
                ),
                _path(
                    'M389 426C375 416 359 412 339 426'
                ),
                _path(
                    'M501 442C528 452 557 510 509 541'
                ),
                _path(
                    'M451 611C464 630 527 647 555 607'
                )
            )),

            // X'D OUT
            string(abi.encodePacked(
                _line(
                    [372, 508, 410, 470],
                    'r'
                ),
                _line(
                    [372, 470, 410, 508],
                    'r'
                ),
                _line(
                    [597, 462, 635, 500],
                    'r'
                ),
                _line(
                    [597, 500, 635, 462],
                    'r'
                ),
                _eyes([616, 417, 391, 417]),
                _path(
                    'M539 558C535 576 516 586 499 582C481 577 471 559 475 541C480 523 498 513 516 517C534 522 544 540 539 558Z'
                )
            )),

            // 2COOL
            string(abi.encodePacked(
                _line([610, 423, 400, 423]),
                _line([545, 472, 465, 472]),
                _path(
                    'M475 629C495 616 540 629 558 618'
                ),
                _path(
                    'M652 460C641 476 608 518 565 550'
                ),
                _path(
                    'M442 460C431 476 398 518 355 550'
                ),
                _path(
                    'M676 490C666 505 637 542 599 570', 's3'
                ),
                _path(
                    'M466 490C456 505 427 542 389 570', 
                    's3'
                ),
                _path(
                    'M332 515C339 553 375 577 412 570C449 563 473 527 466 489C459 452 423 428 386 435C349 442 325 478 332 515Z'
                ),
                _path(
                    'M542 516C549 553 585 577 622 570C659 563 683 527 676 490C668 453 633 428 596 436C559 443 535 479 542 516Z'
                )
            )),

            // STONEY
            string(abi.encodePacked(
                _path(
                    'M360 435C369 419 414 404 435 435'
                ),
                _path(
                    'M558 435C567 419 612 404 633 435'
                ),
                _path(
                    'M526 489C529 536 465 538 463 493'
                ),
                _path(
                    'M389 541C383 658 593 682 601 546'
                ),
                _path(
                    'M521 523C523 558 476 560 473 527',
                    's1'
                )
            )),

            // JOYFUL
            string(abi.encodePacked(
                _path(
                    'M362 483C362 425 469 417 469 486'
                ),
                _path(
                    'M538 488C538 429 643 421 644 490'
                ),
                _path(
                    'M427 557C454 606 554 605 579 557'
                )
            )),

            // FUNHAPPY
            string(abi.encodePacked(
                _eyes([343, 461, 664, 461]),
                _path(
                    'M399 559C398 417 610 397 611 564'
                )
            )),

            // STRAIGHT TALKER
            string(abi.encodePacked(
                _line(
                    [370, 427, 424, 427],
                    'r'
                ),
                _line(
                    [567, 427, 623, 427],
                    'r'
                ),
                _eyes([397, 463, 596, 463]),
                _path(
                    'M443 552C458 561 532 569 566 552'
                )
            )),

            // BITEY
            string(abi.encodePacked(
                _eyes([419, 480, 610, 477]),
                _path(
                    'M655 430C645 424 600 427 583 446'
                ),
                _path(
                    'M374 436C384 429 429 428 447 446'
                ),
                _path(
                    'M622 536C615 549 605 565 588 576M415 552C430 569 437 572 449 581M588 576L589 616L564 588M588 576C580 580 572 584 564 588M564 588C537 598 506 602 477 593M477 593L453 621L449 581M477 593C467 590 458 586 449 581'
                )
            ))

        ];

        return
            faces[uint256(keccak256(abi.encodePacked("FACE", tokenId))) % faces.length];
    }


	/** @dev Internal function that returns the weird face associated with the given token ID.
      * @notice This function will return a face for ANY token, even non-Weird Youts.  
	  * @param tokenId A token's numeric ID. 
	  */
    function _weirdFace(uint256 tokenId) 
        internal 
        pure 
        returns (string memory) 
    {
        string[14] memory faces = [
            
            // SPIRIT / NORTH TREE
            string(abi.encodePacked(
                _eyes([311, 482, 585, 591]),
                '<circle class="s0" cx="497" cy="416" r="33.5"/>'
            )),

            // SPIRIT / EAST TREE
            string(abi.encodePacked(
                _eyes([381, 600, 438, 363]),
                '<circle class="s0" cx="578" cy="537" r="33.5"/>'
            )),

            // SPIRIT / WEST TREE
            string(abi.encodePacked(
                _eyes([514, 567, 489, 349]),
                '<circle class="s0" cx="366" cy="524" r="33.5"/>'
            )),

            // SPIRIT / SOUTH TREE
            string(abi.encodePacked(
                _eyes([320, 496, 583, 364]),
                '<circle class="s0" cx="470" cy="542" r="33.5"/>'
            )),

            // SPIRIT / CENTER TREE
            string(abi.encodePacked(
                _eyes([292, 481, 628, 392]),
                '<circle class="s0" cx="471" cy="474" r="33.5"/>'
            )),

            // ALIEN / U-SHAPE
            string(abi.encodePacked(
                _eyes([507, 456, 454, 456]),
                _path(
                    'M446 540C446 581 521 585 521 538'
                ),
                '<circle class="s0" cx="606" cy="441" r="56.5"/>',
                '<circle class="s0" cx="348" cy="451" r="56.5"/>'
            )),

            // ALIEN / O-SHAPE
            string(abi.encodePacked(
                _eyes([467, 515, 522, 510]),
                '<circle class="s0" cx="503" cy="626" r="33.5"/>',
                '<circle class="s0" cx="343" cy="510" r="56.5"/>',
                '<circle class="s0" cx="625" cy="476" r="56.5"/>'
            )),

            // ALIEN / INVERTED U-SHAPE
            string(abi.encodePacked(
                _eyes([509, 491, 465, 492]),
                _path(
                    'M529 646C529 603 453 610 459 646'
                ),
                '<circle class="s0" cx="353" cy="472" r="56.5"/>',
                '<circle class="s0" cx="620" cy="470" r="56.5"/>'
            )),

            // ALIEN / ROTATED I-SHAPE
            string(abi.encodePacked(
                _eyes([509, 491, 456, 491]),
                _path(
                    'M439 584C450 583 505 582 530 584'
                ),
                '<circle class="s0" cx="344" cy="461" r="56.5"/>',
                '<circle class="s0" cx="623" cy="455" r="56.5"/>'
            )),

            // PRIMORDIAL / ALIGNED
            string(abi.encodePacked(
                _eyes([497, 414, 496, 668]),
                _path(
                    'M451 605C462 624 517 643 542 605'
                ),
                _path(
                    'M425 345C445 373 529 391 559 328'
                ),
                _path(
                    'M397 572C396 448 592 431 593 577'
                )
            )), 

            // PRIMORDIAL / FOUR EYES
            string(abi.encodePacked(
                _eyes([588,496,354,497]),
                _eyes([359,407,591,408]),
                _path(
                    'M662 411.353C646 382 565 353 527 411'
                ),
                _path(
                    'M428 411.797C412 382 331 353 293 411'
                ),
                _path(
                    'M657 499.553C641 470 559 442 522 501'
                ),
                _path(
                    'M423 499.999C407 470 325 442 288 501'
                ),
                _path(
                    'M288 553.666C279 679 650 708 661 562'
                )
            )),

            // PRIMORDIAL / SPIRALING
            string(abi.encodePacked(
                _eyes([357,601,586,356]),
                _path(
                    'M399 620C505 654 684 574 561 391C609 546 469 629 399 620Z'
                ),
                _path(
                    'M398 576C304 505 324 295 550 339C405 344 349 497 398 576Z'
                )
            )),

            // PRIMORDIAL / CYCLOPS
            string(abi.encodePacked(
                '<circle class="s0" cx="474" cy="433" r="49"/>',
                '<circle class="fB i" cx="474" cy="433"/>',
                _path(
                    'M288.098 487.326C281.091 709.646 652.733 747.352 660.929 487.326'
                )
            )),

            // PRIMORDIAL / PRIMAL
            string(abi.encodePacked(
                _eyes([611,489,473,492]),
                '<circle class="fB i" cx="337" cy="489" r="12"/>',
                _path(
                    'M541.847 495.922C542.363 588.19 405.284 600.773 404.68 492.855',
                    ''
                ),
                _path(
                    'M279.036 481.07C279.073 487.698 273.73 493.1 267.103 493.137C260.476 493.174 255.073 487.832 255.036 481.205L279.036 481.07ZM255.036 481.205C254.738 427.86 294.758 396.997 334.783 395.609C354.81 394.914 375.274 401.533 390.803 416.613C406.432 431.79 416.037 454.525 416.203 484.137L392.203 484.271C392.067 459.925 384.311 443.763 374.083 433.831C363.756 423.802 349.87 419.099 335.616 419.594C307.079 420.584 278.818 442.147 279.036 481.07L255.036 481.205Z',
                    'fB nS'
                ),
                _path(
                    'M691.203 491.137C691.24 497.764 685.898 503.167 679.27 503.204C672.643 503.241 667.24 497.899 667.203 491.271L691.203 491.137ZM530.036 488.205C529.738 434.86 569.758 403.997 609.783 402.609C629.81 401.914 650.274 408.533 665.803 423.613C681.432 438.79 691.037 461.525 691.203 491.137L667.203 491.271C667.067 466.925 659.311 450.763 649.083 440.831C638.756 430.802 624.87 426.099 610.616 426.594C582.079 427.584 553.818 449.147 554.036 488.07L530.036 488.205Z',
                    'fB nS'
                )
            ))

        ];

        return
            faces[uint256(keccak256(abi.encodePacked('FACE', tokenId))) % faces.length];
    }


	/** @dev Internal drawing helper function that draws two eye dots.
	  * @param position An array containing the X and Y coordinates for each eye (X1, Y1, X2, Y2)
	  */
    function _eyes(uint16[4] memory position)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<circle class="fB i" cx="',
                position[0].uint2str(),
                '" cy="',
                position[1].uint2str(),
                '"/>',
                '<circle class="fB i" cx="',
                position[2].uint2str(),
                '" cy="',
                position[3].uint2str(),
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that draws a line.
	  * @param position An array containing the X and Y coordinates for each of the line's end points (X1, Y1, X2, Y2).
	  */
    function _line(uint16[4] memory position)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<line x1="',
                position[0].uint2str(),
                '" y1="',
                position[1].uint2str(),
                '" x2="',
                position[2].uint2str(),
                '" y2="',
                position[3].uint2str(),
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that draws a line with the provided class attribute.
	  * @param position An array containing the X and Y coordinates for each of the line's end points (X1, Y1, X2, Y2).
      * @param classNames A string containing the path's `class` attribute
	  */
    function _line(uint16[4] memory position, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<line x1="',
                position[0].uint2str(),
                '" y1="',
                position[1].uint2str(),
                '" x2="',
                position[2].uint2str(),
                '" y2="',
                position[3].uint2str(),
                '" class="',
                classNames,
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with a default class attribute.
	  * @param d A string containing the path's `d` attribute
	  */
    function _path(string memory d) 
        internal 
        pure 
        returns (string memory) 
    {
        return 
            string(abi.encodePacked(
                '<path class="r" d="', d, '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with the provided class attribute.
	  * @param d A string containing the path's `d` attribute.
	  * @param classNames A string containing the path's `class` attribute
	  */
    function _path(string memory d, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return 
            string(abi.encodePacked(
                '<path class="', classNames, '" d="', d, '"/>'
            ));
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

interface IBody {
    function isRobed(uint256 tokenId) external pure returns (bool);
    function metadata(uint256 tokenId) external pure returns (string memory);
    function element(uint256 tokenId) external pure returns (string memory);
}

/** @title Youts - Body Metadata contract 
  * @author @ok_0S / weatherlight.eth
  */
contract Body {

    string[16] private divineOrderNames = [
        "Power",
        "Giants",
        "Titans",
        "Skill",
        "Perfection",
        "Brilliance",
        "Enlightenment",
        "Protection",
        "Anger",
        "Rage",
        "Fury",
        "Vitriol",
        "the Fox",
        "Detection",
        "Reflection",
        "the Twins"
    ];


	/** @dev External wrapper function that returns true if a Yout has the Robe body type
	  * @param tokenId A token's numeric ID. 
	  */
    function isRobed(uint256 tokenId)
        external 
        pure 
        returns (bool) 
    {
        return _isRobed(tokenId);
    }

	
    /** @dev Internal function that returns true if a Yout has the Robe body type
	  * @param tokenId A token's numeric ID. 
	  */
    function _isRobed(uint256 tokenId) 
        internal 
        pure 
        returns (bool) 
    {
        return uint256(keccak256(abi.encodePacked("ROBED", tokenId))) % 100 < 7 ? true : false;
    }


    /** @dev Internal function that returns the Divine Order index for this token
      * @notice This function will return a Divine Order index for ANY token, even Youts that aren't wearing Divine Robes. 
	  * @param tokenId A token's numeric ID. 
	  */
    function _divineIndex(uint256 tokenId)
        internal
        pure
        returns (uint256) 
    {
        return uint256(keccak256(abi.encodePacked("DIVINEORDER", tokenId))) % 16;
    }


	/** @dev Renders a JSON string containing metadata for a Yout's body
	  * @param tokenId A token's numeric ID. 
	  */
    function metadata(uint256 tokenId) 
        external
        view
        returns (string memory)
    {
        string memory traits;
        bool robeCheck = _isRobed(tokenId);

        traits = string(abi.encodePacked(
            '{"trait_type":"Body Type","value":"', robeCheck ? "Divine Robe" : "Outline", '"}'
        ));

        if (robeCheck) {
            traits = string(abi.encodePacked(
                traits,',',
                '{"trait_type":"Divine Order","value":"', divineOrderNames[_divineIndex(tokenId)], '"}'
            ));
        }

        return traits;
    }


	/** @dev Renders a SVG element containing a Yout's body  
	  * @param tokenId A token's numeric ID. 
	  */
    function element(uint256 tokenId)
        external
        pure
        returns (string memory)
    {
        string memory body;

        if (_isRobed(tokenId)) {

            string[16] memory divineOrders = [

                // POWER
                string(abi.encodePacked(
                    '<path class="r" d="M628 840L600 879H639L613 918"/>'
                )),

                // GIANTS
                string(abi.encodePacked(
                    '<circle class="fB" cx="625" cy="842" r="11"/>',
                    '<path class="r mJ" d="M594 909V882.2L624 860L654 882.2V909"/>'
                )),

                // TITANS
                string(abi.encodePacked(
                    '<line class="r" x1="625" y1="845" x2="625" y2="902"/>',
                    '<path class="r mJ" d="M595 906V870L625 840L655 870V906"/>'
                )),

                // SKILL
                string(abi.encodePacked(
                    '<path class="r" d="M620.5 846.5L620.5 922"/>',
                    '<path class="r mJ" d="M597 862L620.5 834L644 862"/>',
                    '<path class="r mJ" d="M597 902L620.5 873L644 902"/>'
                )),

                // PERFECTION
                string(abi.encodePacked(
                    '<line class="r" x1="598" y1="902.73" x2="610.73" y2="890"/>',
                    '<line class="r" x1="646" y1="854.14" x2="633.27" y2="866.87"/>',
                    '<line class="r" x1="10" y1="-10" x2="28" y2="-10" transform="matrix(0.71 0.71 0.71 -0.71 598 841)"/>',
                    '<line class="r" x1="10" y1="-10" x2="28" y2="-10" transform="matrix(-0.71 -0.71 -0.71 0.71 645.87 915.87)"/>'
                )),

                // BRILLIANCE
                '<path class="r" d="M625.35 838C625.61 850.54 618.49 875.62 588 875.62C600.45 874.44 625.35 880.47 625.37 914C625.2 901.2 631.26 875.62 661 875.62C650.28 876.08 625.35 869.2 625.35 838Z"/>',

                // ENLIGHTENMENT
                string(abi.encodePacked(
                    '<circle cx="623.5" cy="868.5" r="27.5"/>',
                    '<line class="r" x1="585" y1="913" x2="661" y2="913"/>'
                )),

                // PROTECTION
                string(abi.encodePacked(
                    '<line x1="617.881" y1="869.216" x2="631.881" y2="883.216"/>',
                    '<circle cx="625" cy="876" r="32.5"/>'
                )),

                // ANGER
                '<path class="r mJ" d="M586.5 911.5L624.3 900.28M659.5 911.5L624.3 900.28M624.3 900.28C615.83 889.54 594 877 624.3 843C654.5 877.5 632.47 890.13 624.3 900.28Z"/>',

                // RAGE
                string(abi.encodePacked(
                    '<path class="r mJ" d="M599 845L624.5 905L650 845"/>',
                    '<line class="r" x1="595" y1="890" x2="655" y2="890"/>'
                )),

                // FURY
                string(abi.encodePacked(
                    '<path class="r mJ" d="M590 909C590 892.42 606.99 848 633.76 848C629.25 868 627.81 899.52 655 899.52"/>'
                )),

                // VITRIOL
                string(abi.encodePacked(
                    '<path class="r mJ" d="M610 845L580 875L610 905"/>',
                    '<line class="r" x1="661" y1="874" x2="651" y2="874"/>',
                    '<line class="r" x1="639" y1="851.142" x2="626.272" y2="863.87"/>',
                    '<line class="r" x1="10" y1="-10" x2="28" y2="-10" transform="matrix(-0.71 -0.71 -0.71 0.71 638.87 912.87)"/>'
                )),

                // THE FOX
                '<path class="r" d="M651 883.59L651 843L640.97 862.02L609.77 862.02L599 843L599 883.59L625 909L651 883.59Z"/>',

                // DETECTION
                string(abi.encodePacked(
                    '<circle cx="622" cy="866" r="17"/>',
                    '<circle cx="621.5" cy="885.5" r="36.5"/>'
                )),

                // REFLECTION
                string(abi.encodePacked(
                    '<path class="r" d="M625 838L625 916"/>',
                    '<path class="r" d="M645 878.421L658 860V895L645 878.421Z"/>',
                    '<path class="r" d="M605 878.421L592 860V895L605 878.421Z"/>'
                )),

                // THE TWINS
                string(abi.encodePacked(
                    '<line  x1="637" y1="911" x2="637" y2="844"/>',
                    '<line  x1="608" y1="911" x2="608" y2="844"/>',
                    '<line  class="s2 r" x1="589" y1="905" x2="655" y2="905"/>',
                    '<line  class="s2 r" x1="589" y1="854" x2="655" y2="854"/>'
                ))
                
            ];

            body = string(abi.encodePacked(
                '<g id="r">',
                    '<path id="i" d="M737.999 513.386C737.999 555.412 716.499 649.541 646.499 687.5C600.484 709.932 520.232 763.378 468.087 837.218C474.384 794.807 368.783 723.368 314 692.336C244 654.377 210 555.412 210 513.386C210 471.36 192.999 227.338 473.999 227.338C754.999 227.338 737.999 471.36 737.999 513.386Z"/>',
                    '<path class="s3" d="M314 776.388C244 738.429 134.031 751.5 147.031 511.5C149.304 469.535 150 181.004 473 181.004C796 181.004 793.727 469.539 796 511.504C809 751.504 701 734.541 631 772.5M314 776.388C354.156 791.388 430 855 432 905M314 776.388C257.2 811.093 199.667 910.148 178 955.338M631 772.5C596.167 787.167 513.999 842.504 483.999 952.504M631 772.5C687.8 807.205 748.333 910.148 770 955.338M468.087 837.218C520.232 763.378 600.484 709.932 646.499 687.5C716.499 649.541 737.999 555.412 737.999 513.386C737.999 471.36 754.999 227.338 473.999 227.338C192.999 227.338 210 471.36 210 513.386C210 555.412 244 654.377 314 692.336C368.783 723.368 474.384 794.807 468.087 837.218ZM468.087 837.218C444.684 870.357 426.942 907.605 420.499 948"/>',
                    '<g id="do">',
                        divineOrders[_divineIndex(tokenId)],
                    '</g>',
                '</g>'
            ));

        } else {

            body = string(abi.encodePacked(
                '<g id="b">',
                    '<path class="s3 eO" d="M174 955C195.67 909.8 253.2 810.8 310 776.05C381 732.7 380 730 310 692C240 654 206 555.1 206 513.05C206 471 189 227 470 227C751 227 734 471 734 513.05C734 555.1 700 654 630 692C560 730 559 732.7 630 776.05C686.8 810.8 744.3 909.8 766 955H174ZM174 955H765"/>',
                '</g>'
            ));

        }

        return body;
    }


}

// SPDX-License-Identifier: MIT

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
pragma solidity >=0.8.0 <0.9.0;

library Uint2str {


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    
}