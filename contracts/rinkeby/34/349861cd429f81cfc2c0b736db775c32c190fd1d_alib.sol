/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library alib {
    function afuncy(uint a) public view returns (uint) {
        return a;
    }
}

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint seed;
    uint8[] seeds;
    function seedcheck() public view returns (uint8) {
        //return seed;
        uint8[] memory a = seeds;
        return a[2];
    }

    function testinglib (uint a) public view returns (uint) {

        return alib.afuncy(a);
    }

    struct Asdf
    {
        uint256 a;
        uint256 b;
        uint256 c;
    }
    Asdf asdf;

    struct Test1
    {
        uint256 a;
    }
    Test1 test1;

    struct Test2
    {
        uint8 y;
        uint8 t;
        uint8 r;
        uint8 e;
        uint8 w;
        uint8 q;
        uint8 l;
        uint8 k;
        uint8 j;
        uint8 h;
        uint8 g;
        uint8 f;
        uint8 d;
        uint8 s;
        uint8 a;
        uint8 m;
        uint8 n;
        uint8 b;
        uint8 v;
        uint8 c;
        uint8 x;
        uint8 z;
        uint8 za;
        uint8 zs;
        uint8 zd;
        uint8 zf;
        uint8 zg;
        uint8 zh;
        uint8 zj;
        uint8 zk;
        uint8 zx;
        uint8 zn;
    }
    Test2 test2;
    uint256 number;

    /**
     * @dev Store value in variable
     */
     function store1() public {
         uint256 a = 0;
         a |= 2<<8;
         a |= 2<<16;
         a |= 2<<24;
         a |= 2<<32;
         a |= 2<<40;
         a |= 2<<48;
         a |= 2<<56;
         a |= 2<<64;
         a |= 2<<72;
         a |= 2<<80;
         a |= 2<<88;
         a |= 2<<96;
         a |= 2<<104;
        test1 = Test1(a);
    }

    function GenerateColors (uint256 tokenId) public view returns (uint256[] memory)
    {
        uint256[] memory asdf = new uint256[](32);
        for (uint i = 0; i < 32; i++)
        {
            asdf[i] = i+tokenId;
        }
        return asdf;
    }
    //more gas
    function GenerateColors2 (uint256 tokenId) public view returns (uint8[] memory)
    {
        uint8[] memory asdf = new uint8[](32);
        for (uint i = 0; i < 32; i++)
        {
            asdf[i] = uint8(i+tokenId);
        }
        return asdf;
    }

    function t1 (uint tokenid, uint seed) public view returns (uint256)
    {
        uint a = 0;
        for (uint i = 0; i < 10; i++)
        {
            a += tokenid + seed;
        }

        return a;
    }
    //this is cheaper
    function t2 (uint tokenid, uint seed) public view returns (uint256)
    {
        uint a = 0;
        uint b = tokenid + seed;
        for (uint i = 0; i < 10; i++)
        {
            a += b;
        }

        return a;
    }

    function editstore1() public view returns (uint256) {

        uint256 col = 50;
                col |= 100<<8;
                col |= 25<<16;
                col |= 3034<<32;
        return uint256(uint8(col>>16));
    }
    function editstore2() public view returns (uint256) {

        uint256 col = 50;
                col |= 100<<7;
                col |= 1958<<14;
                col |= 17<<21;
        return uint256(uint8(col>>14));
    }
    function editstore3() public view returns (uint256) {

        uint256 col;
        col |= 127;
        col |= 12<<7;
        col |= 17<<14;

        uint8 mask = 0x7f;
        uint8 t = uint8(col>>7) & mask;

        return uint256(t);
        //https://testnets.opensea.io/assets/0x0f292ae85e92dd1b6ab253d7aa9bead8f0924b41/1
    }

    function shiftLeft(uint8 a, uint8 n) public view returns (uint8) {
        uint8 shifted = uint8(uint8(a) * 2 ** n);
        return shifted;
    }


    function store2() public {
        test2 = Test2(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
    }
    function store3() public {
        //uint8 a = 2 + 5;
        test2 = Test2(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    function generateImage() public pure returns (string memory) {




        return string(
            abi.encodePacked(
                '<svg class="svgBody" width="300" height="300" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg">',
                '<text x="215" y="80" class="small">ANCHOR CITY</text>',
                '<text x="15" y="120" class="medium">REASON:</text>',
                '<rect x="15" y="125" width="205" height="40" style="fill:white;opacity:0.5"/>',
                '<text x="15" y="190" class="small">SPONSORED BY:</text>',
                '<text x="15" y="230" class="tiny">Under Section 1.C of the Uploaded Minds And Human</text>',
                '<text x="15" y="240" class="tiny">Coexistence Pact: The Bearer Is Re-Entitled To The Freedom</text>',
                '<text x="15" y="250" class="tiny">of Earth. If Sponsored, Under Section 6.F: The Bearer</text>',
                '<text x="15" y="260" class="tiny">Has Immediate Access To The Inner Bandwidth Wells.</text>',
                '<text x="15" y="270" class="tiny">Under Section 9.A: If Destroyed, Bearer Will Be Delisted.</text>',
                '<style>.svgBody {font-family: "Courier New" } .tiny {font-size:6px; } .small {font-size: 12px;}.medium {font-size: 18px;}</style>',
                '</svg>'
            )
        );
    }


    /*function asas () public view returns (uint)
    {
        uint z = 0;
        uint x = 0;
        uint c = 0;
        uint v = 0;
        uint b = 0;
        uint n = 0;
        uint m = 0;
        uint q = 0;
        uint w = 0;
        uint e = 0;
        uint r = 0;
        uint t = 0;
        uint y = 0;
        uint u = 0;
        uint i = 0;
        uint o = 0;
        return u;
    }*/

    struct afafaf {
        uint a;
        uint b;
        uint c;
        uint d;
        uint e;
        uint f;
        uint g;
        uint h;
        uint i;
        uint j;
    }

    function a1 (uint a) public view returns (uint) {
        //afafaf memory x = afafaf(a,a,a,a,a);
        return a+a+a+a+a+a+a+a+a+a;
    }
    function a2 (uint a) public view returns (uint) {
        afafaf memory x = afafaf(a,a,a,a,a,a,a,a,a,a);
        return x.a+x.b+x.c+x.d+x.e+x.f+x.g+x.h+x.i+x.j;
    }
    function a3 (uint a, uint b) public view returns (uint) {

        //return a + b + a + b + a;
    }
    function a4 (afafaf memory id) public view returns (uint) {
        //return id.a + id.b + id.c + id.d + id.e;
        
    }
    

    struct Col
    {
        uint h;
        uint s;
        uint l;
    }
}