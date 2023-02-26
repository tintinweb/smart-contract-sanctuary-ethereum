/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

pragma solidity ^0.8.18;
contract Testing {
    IPunkBlocks pb; // 0x58E90596C2065BEfD3060767736C829C18F3474c

    constructor(address _b) {
        pb = IPunkBlocks(_b);
    }

    function doesntWork() external view returns(IPunkBlocks.Block memory) {
        // This works if you call the contract's pb.blocks() method directly via web3
        // https://etherscan.io/address/0x58E90596C2065BEfD3060767736C829C18F3474c#readContract
        // 0x1885.. is a valid key, it exists.
        IPunkBlocks.Block memory test = pb.blocks(0x1885fe71e225eade934ab7040d533bd49efc5d66e8f2d4b5aa42477ae9892ec9);
        return test;
    }

    function works() external view returns(IPunkBlocks.Block memory) {
        IPunkBlocks.Block memory test = pb.blocks(0x1BB61A688FEA4953CB586BAA1EADB220020829A1E284BE38D2EA8FB996DD7286);
        return test;
    }

}

interface IPunkBlocks {
    enum Layer {
        Base,      // 0 Base is the face. Determines if m or f version will be used to render the remaining layers
        Cheeks,    // 1 (Rosy Cheeks)
        Blemish,   // 2 (Mole, Spots)
        Hair,      // 3 (Purple Hair, Shaved Head, Pigtails, ...)
        Beard,     // 4 (Big Beard, Front Beard, Goat, ...)
        Eyes,      // 5 (Clown Eyes Green, Green Eye Shadow, ...)
        Eyewear,   // 6 (VR, 3D Glass, Eye Mask, Regular Shades, Welding Glasses, ...)
        Nose,      // 7 (Clown Nose)
        Mouth,     // 8 (Hot Lipstick, Smile, Buck Teeth, ...)
        MouthProp, // 9 (Medical Mask, Cigarette, ...)
        Earring,   // 10 (Earring)
        Headgear,  // 11 (Beanie, Fedora, Hoodie, Police Cap, Tiara, Headband, ...)
        Neck       // 12 (Choker, Silver Chain, Gold Chain)
    }
    struct Block {
        Layer layer;     // 13 possible layers
        bytes dataMale;  // male version of this attribute
        bytes dataFemale;// female version of this attribute
    }
    function blocks(bytes32) external view returns(Block memory);
}