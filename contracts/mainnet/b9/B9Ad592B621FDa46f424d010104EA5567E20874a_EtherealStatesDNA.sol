// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title EtherealStatesDNA
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice Generates DNA for EtherealStates NFTs
///         A big thank you to cxkoda (https://twitter.com/cxkoda) who helped me with the bit manipulation
///         & assembly and saved quite some gas.
contract EtherealStatesDNA {
    error WrongDistributionForLayer(uint256 layer, uint256 acc);

    function checkLayersValidity() public pure {
        unchecked {
            bytes memory layer;
            uint256 acc;
            uint256 i;
            for (uint256 j; j < 20; j++) {
                layer = getLayer(j);
                acc = 0;
                assembly {
                    for {
                        let current := add(layer, 0x20)
                        let length := mload(layer)
                    } lt(i, length) {
                        current := add(current, 2)
                        i := add(i, 2)
                    } {
                        acc := add(acc, sar(240, mload(current)))
                    }
                    i := 0
                }

                if (acc != 10000) {
                    revert WrongDistributionForLayer(j, acc);
                }
            }
        }
    }

    function generate(uint256 seed, bool includeHolderTraits)
        public
        pure
        returns (bytes32)
    {
        uint256 dna;
        uint256 random;

        unchecked {
            for (uint256 i; i < 20; i++) {
                // keccak the seed, very simple prng
                // we do it on each call, because even if Holders layer is not shown we want to be sure
                // the layers after stay the same with or without it
                seed = uint256(keccak256(abi.encode(seed)));

                // next random number
                random = seed % 10000;

                // push 8 null bits on the right side
                dna <<= 8;

                // done here and not in consumer, because getLayer(i) and pickOne are costly operations.
                // this way we save the gas when the trait is not included
                if (i != 12 || includeHolderTraits) {
                    // set the last 8 bits to the index of the asset in the layer
                    dna |= _pickOne(getLayer(i), random);
                }
            }

            // add 96 null bits right
            dna <<= 96;
        }
        return bytes32(dna);
    }

    function _pickOne(bytes memory layer, uint256 chance)
        public
        pure
        returns (uint256)
    {
        unchecked {
            uint256 i;
            assembly {
                for {
                    let current := add(layer, 0x20)
                    let acc
                } 1 {
                    // add 2 bytes to current position
                    current := add(current, 2)
                    i := add(i, 2)
                } {
                    // add the value of the 2 first bytes of current in acc
                    acc := add(acc, sar(240, mload(current)))
                    // if chance < acc
                    if lt(chance, acc) {
                        break
                    }
                }
                i := sar(1, i)
            }
            return i;
        }
    }

    // this is pretty dirty but this saves quite some gas
    // 1) putting the layers in storage would be very expensive when deploying & when reading storage
    // 2) using arrays of uint for that many assets (512), is too big for a contract
    // After tests, this seems to be a good working compromise
    function getLayer(uint256 which) public pure returns (bytes memory layer) {
        if (which == 0)
            layer = hex'01900190017c017c019001900006015e01900040017c00be0190000a0190015e017c017c0190015e001000680190017c0190017c00140020017c0087017c017c00df015e';
        else if (which == 1)
            layer = hex'012e0132007c00a0005e000a012c01e701e7000c000800b4006401e700a201e701e701e701e701bb01e701e7000e01e701b7000c01b701bb007c0130000e01e701e700a6';
        else if (which == 2)
            layer = hex'01b8019001b801b801a4011801cc01cc01cc0168001401cc01cc01b801cc01b801cc01b801b801b801b801cc01a401cc';
        else if (which == 3)
            layer = hex'004b003602080208020802080208004b00780208009102080110020802080208020801ae020801ae0208004f020802080208';
        else if (which == 4)
            layer = hex'007d004002080208020802080208004b020800a502080129020802080208020801c2020801c202080036020802080208';
        else if (which == 5)
            layer = hex'02260226021202120226021200d2012c022600aa02260096004002120212010400780212005602260212021202260226';
        else if (which == 6)
            layer = hex'01c201c200320064017201c201c20172001901c2017201720096017200960172003201c201c2017201c20064001901c2017201720064017201c201c2009601c2';
        else if (which == 7)
            layer = hex'00a01d4c005500780055009f00c700c7000700a000c700c7009f000500780055005500780005001e00c70078';
        else if (which == 8)
            layer = hex'01a901f401b301b301f401b301b301f401f4010e01f401f401b301f401b301f401a901f4005a01f40096001e01f401f4';
        else if (which == 9)
            layer = hex'020801b301b30208020801b300640208003c020800a001b301e501e501b30208015e020801b300c802080208015e0208';
        else if (which == 10)
            layer = hex'01e001fe019a019a01fe01e001fe01e0019a003201e001fe00960069004b01fe01fe01fe01fe01e001e001fe01fe019a';
        else if (which == 11)
            layer = hex'01f401f401f401f4012c01f40194019401e0001401e001f401f401e0000a019401e001e0019401f401f4019400fa01f4';
        else if (which == 12)
            layer = hex'0000032f032f032f032f032f032f01e00154032f01e00226032f032f032f';
        else if (which == 13)
            layer = hex'00780205020502050205008c01e002050205020501e0020500a000c001e001e00036020501e001e0020500fa02050205';
        else if (which == 14)
            layer = hex'020800be01e0020801e001fe01fe01e000fa003c01e0020800640208008c020801e00208020801e002080208020800a0';
        else if (which == 15)
            layer = hex'0194007801e0019401ea01ea01e00194000a019401ea01ea01ea01ea012c01e000fa01ea01ea01e001e001ea01ea0194';
        else if (which == 16)
            layer = hex'003201c2014301c201c2000a0143000f01c20143014301c200a000a00007005001c2003c00a001c2014301c201c201c201c201c201c201c2014301c201c200a0';
        else if (which == 17)
            layer = hex'00a00143005001a401a400f001a4006401a401a401a401a40143014301a4000a01a400f001a401a401a401a401a401a4014a01a400f000a0003c01430143002d';
        else if (which == 18)
            layer = hex'0143005001a401a401a4014301a40082002d01a4000a01a401a400f001a401a401a400a001a4004601a400a001a401430143014301a4017c00f001a4014a00f0';
        else if (which == 19)
            layer = hex'000a000a000a000a000a000a000a000a268e000a000a000a000a000a';
    }
}