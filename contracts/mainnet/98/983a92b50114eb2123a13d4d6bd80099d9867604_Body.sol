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