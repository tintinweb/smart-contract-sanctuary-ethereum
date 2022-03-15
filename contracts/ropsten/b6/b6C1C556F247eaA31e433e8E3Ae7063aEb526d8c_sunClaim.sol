/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;


interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transfer(address dst, uint wad) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function decimals() external view returns (uint8 decimals);
}



contract sunClaim {

    mapping(address => bool) isOwner;
    mapping(address => uint) pubAllo;
    mapping(address => uint) privAllo;
    mapping(address => bool) hasClaimed_pub1;
    mapping(address => bool) hasClaimed_pub2;
    mapping(address => bool) hasClaimed_priv1;
    mapping(address => bool) hasClaimed_priv2;
    mapping(address => bool) hasClaimed_priv3;
    address suntoken = 0x016081868E7eAA33447a738789A459De87042dC6;//0xB3d8D8D659d4dc89699826D46585ac6cB3bEA05A;
    ERC20 TOKEN = ERC20(suntoken);

    constructor() {
        isOwner[msg.sender] = true;
pubAllo	[	0x9aB5C85752fD5A12389271B6d6E86ccf13aC7111	]	=	8250000	;
pubAllo	[	0x5e6cDa012fA9baF45331b649412E114A63151516	]	=	6601622	;
pubAllo	[	0x9aB5C85752fD5A12389271B6d6E86ccf13aC7111	]	=	3300000	;
pubAllo	[	0x96d912adc0E8D8A1e25F19d32653d8F06dbBCcF9	]	=	33000000	;
pubAllo	[	0xA20dC8e6caf2b3bfbc0303224b35892Ae4781E7B	]	=	11000000	;
pubAllo	[	0x02A867d2216E96c48daC65Fa564e827d65Bcd9c3	]	=	7080700	;
pubAllo	[	0x134BD47d928ac034ca81a05e4CE9A721915C1553	]	=	11000000	;
pubAllo	[	0x1e62A12D4981e428D3F4F28DF261fdCB2CE743Da	]	=	11000000	;
pubAllo	[	0x21dAaCB3B5E86692bCDf5805741eBdaFAB4d0B76	]	=	11000000	;
pubAllo	[	0x221A25ab9eB38C4Afe8239b89d8A56B54A4FD0a7	]	=	11000000	;
pubAllo	[	0x2eAD324AE95655b023908B8f25A3228193653b43	]	=	11000000	;
pubAllo	[	0x2eFD967C74cC4321b1eacaA4075Bae7EEc723479	]	=	11000000	;
pubAllo	[	0x36DB7e320769Bb38e1E2863d084f70Cb5Bb63fc3	]	=	11000000	;
pubAllo	[	0x39b5B7d307F27348b1f00A8014564BEBA8B3513c	]	=	4400000	;
pubAllo	[	0x3C4cd9AD8Eb5E686dBF1cC56C762e2fc656bd24e	]	=	2200000	;
pubAllo	[	0x457b4E21545A4d728C4a23CE9388C9e0d4370cDf	]	=	6600000	;
pubAllo	[	0x4886976bD2E822D8483e3363a0843461c3A8a2eB	]	=	11000000	;
pubAllo	[	0x4E2B9A6Ac739733563413df29a0c56D021213Cb8	]	=	11000000	;
pubAllo	[	0x55645A2e1b9124a6862Ea40389C46291909cc062	]	=	11000000	;
pubAllo	[	0x566C6599f9Df969819B3d213B362ad5fe6e39975	]	=	11000000	;
pubAllo	[	0x63b693912bd249636979229F3479bBCEfCb266e7	]	=	6672749	;
pubAllo	[	0x6a5c95590fbA36E360699C0797b7ae5c27175bFd	]	=	22000000	;
pubAllo	[	0x67A974dc51BF69F74e236E063a3877b674196aFF	]	=	6600000	;
pubAllo	[	0x6eC7373F7Ce088d751FCeF11E6009933Db62849d	]	=	11000000	;
pubAllo	[	0x7123E389f37C0aE868F26693b9a041486e4eE14D	]	=	11000000	;
pubAllo	[	0x81F979843eB1Aeb63192fB2806954B2d8d40CaD7	]	=	4400000	;
pubAllo	[	0x96f692E0D794fA46021BDf36E1bc8d8afF8Bc304	]	=	11000000	;
pubAllo	[	0xC508DEE1A2db0f32e0156FF0af62FB0353903d53	]	=	11000000	;
pubAllo	[	0xc9Eb785CFAB7C47e86Dd42A76183c7340c7B4d24	]	=	11000000	;
pubAllo	[	0xD44b4f0Ff68d68D5E1c44C3f906FA2216e648A1A	]	=	2200000	;
pubAllo	[	0xdB94A4F899D1Da8fa0AD202826aBedA7E5825089	]	=	11012361	;
pubAllo	[	0x9af95b4c2209ce92a18a118EF3454d07B2a97Cb6	]	=	8662500	;
pubAllo	[	0xE5287EdF1e5a9C71F0890743D785b09306d7c9Aa	]	=	2200000	;
pubAllo	[	0xe61868C50f3D565DA4bC23b05c282C9d5aC5297D	]	=	11000000	;
pubAllo	[	0xe9ad315bF094faB4f5466D0083Fff8E91C923adD	]	=	2200000	;
pubAllo	[	0xF1633c382282fe44e999Cf110714301f04AA0825	]	=	11000000	;
pubAllo	[	0xF26802713fA70057f2D63b693960C830357c7501	]	=	11000000	;
pubAllo	[	0xFc4d1E48bF228346a39c6af3b78B19ECCA1cFC98	]	=	22000000	;

privAllo	[	0x830BBe006C2Ed0a4c815C9dBd193515e1c4B06cd	]	=	15625000	;
privAllo	[	0x20BCe045Cb22Bc88346cE0948F3C2314186037c5	]	=	15625000	; 
privAllo	[	0x02A867d2216E96c48daC65Fa564e827d65Bcd9c3	]	=	15625000	;
privAllo	[	0xBD488d1AC171F03B76B4313cFF7D062D80c58215	]	=	12500000	;
privAllo	[	0x408701FB25f39BA924e52534bF8f53De600714fD	]	=	12500000	;
privAllo	[	0x0Ee7686b4710cBEdcaDa11FdC8C9F5c22058fE38	]	=	6250000	;
privAllo	[	0x586A404bd915E2e92Db83fE5Bd981c3c0bFa4624	]	=	6250000	;
privAllo	[	0x742DC6a4cfDe695a9a9c5bF1ce6fA1605a5218d8	]	=	37500000	;
privAllo	[	0x3b3534FBedDC402AbaD4E779994700EF2fFE8ac8	]	=	6250000	;
privAllo	[	0x3b9A8249A749098c7dB331aE353Dfd50DF06929e	]	=	5000000	;
privAllo	[	0x7ca72c5E66C84942b3ce14e378B8A838BAd1B2d9	]	=	18562500	;
privAllo	[	0xA9E5De97602302745B0875b1D1678F15B36E57A6	]	=	1856250	;
privAllo	[	0x0b89f9Dd41DBFB165565C52B5163889be454Ca90	]	=	5568750	;
privAllo	[	0x11b53D1dAC74F1038A63e12651E5C4341Fc19d5f	]	=	18562500	;
privAllo	[	0x5Fa9099B27F7F5760980b027aA7652b18A904348	]	=	18562500	;
privAllo	[	0x20BCe045Cb22Bc88346cE0948F3C2314186037c5	]	=	853875	;
privAllo	[	0x32161c884Bd0c616876eFCAA7750fE9f13C98360	]	=	1856250	;
privAllo	[	0x33e2aaC3EF77374d157276DD1455f23Ad5dbDcAF	]	=	18562500	;
privAllo	[	0x36A7FcaF41b24e488f4C5eCEF2dFD06985442467	]	=	1856250	;
privAllo	[	0x4812c3819320F146D3fefF0A3DD393fD7cFD1672	]	=	3712500	;
privAllo	[	0x49BACE623D636cABb135E32F75C38f71b196D30D	]	=	9281250	;
privAllo	[	0x4ce30368c16477B5dE9F61309806Bc452d144BbD	]	=	1856250	;
privAllo	[	0x558fE5284F10a1231FA2509f20F9626b5BEDF670	]	=	18562500	;
privAllo	[	0x586A404bd915E2e92Db83fE5Bd981c3c0bFa4624	]	=	18562500	;
privAllo	[	0x5E5b632873076e176971994C9a76706423720A84	]	=	9281250	;
privAllo	[	0x611Cbcf375fbD0BDAd0b47B7F9911e943a2a136b	]	=	9281250	;
privAllo	[	0x63E71839bCeBDecf19f049017432D4f2C170196a	]	=	9281250	;
privAllo	[	0x6a5c95590fbA36E360699C0797b7ae5c27175bFd	]	=	9281250	;
privAllo	[	0x448E5C2E2ab8A0572C5e55Fbe2b50502A7Fc95BD	]	=	18562500	;
privAllo	[	0x25EDeb9f5FFEa60C3Feb89e08308aF72018FC9BE	]	=	18574280	;
privAllo	[	0xC740C2E2bEb26261FFC554e29EB9b28fD874dF5c	]	=	18562500	;
privAllo	[	0xa0194D9a21C159167f9392520196AB39Eba507d5	]	=	18648968	;
privAllo	[	0xC4A171992cf93066f825F9752a7F650D1A87e2DF	]	=	18562500	;
privAllo	[	0xB524D7c3d04bd07bC80E6b994239Ce89814f0BE5	]	=	18562500	;
privAllo	[	0x74eFb008c60E9a910cb00C46791676DAf35f05A3	]	=	18562500	;
privAllo	[	0x79DC23C1D2a154F23a5c65de87C588A28063fC5E	]	=	18562500	;
privAllo	[	0x82097C776a100adC4cbDcb8C2799bd03b98B984c	]	=	18562500	;
privAllo	[	0x8248c2527d61ca3DAa9495Bd9ACB878eB6E7B0bb	]	=	18562500	;
privAllo	[	0x85C4B658AE01b9E445Cc941A6183894758598668	]	=	18562500	;
privAllo	[	0x91920Ad1664D284867efDb630221B48ac9d8e9dE	]	=	18562500	;
privAllo	[	0x989303a0A5A60956267bcA39f5441863cb46c6f2	]	=	18562500	;
privAllo	[	0x98E413b4c377be827DeCdbA8A1b6802F7b4A9aC9	]	=	3712500	;
privAllo	[	0x9d4979cD1861a73c62a6DCAF698f7b812318cf29	]	=	3712500	;
privAllo	[	0x9e51a28349c8a68C6Bf55080784E4E87C85A1f44	]	=	18562500	;
privAllo	[	0x9ef28887781E9AD0B1abA2e0693A3F8A69716CaE	]	=	9281250	;
privAllo	[	0xA4b1a7D82b63280d259006adBCB7FB61624B68b9	]	=	18562500	;
privAllo	[	0xBEC826E8b78E52093Df8d4169f506F41A6bFE15e	]	=	9281250	;
privAllo	[	0xC14C43fB61794E803916E3C66fc963F77d7aC095	]	=	18562500	;
privAllo	[	0xC1f1dc0029B41cc2c2861Af71fD38Aa5198b3Be9	]	=	18562500	;
privAllo	[	0xc4C2a5F9C40A76C6C8ec898Dc3c0A6220E196368	]	=	18568316	;
privAllo	[	0xD0c2314A9C74dD4Eb514add7eA4fe1b06E6222C8	]	=	9281250	;
privAllo	[	0xD105609E711ce3771215045864F2Cf0FaE91A70e	]	=	18562500	;
privAllo	[	0xd40bCbce6AC514c2E7EC9620E60C4376F4BA99dc	]	=	7425000	;
privAllo	[	0xD538E9D5557AdC430A0DAC13E8AD1dddb0c6B509	]	=	18564750	;
privAllo	[	0xD5cb038b181dA859a0b5D0601270e1dc1D9c02be	]	=	3712500	;
privAllo	[	0xdF3f38d3BEd0aCac7cDC0f15514F1710137A6e75	]	=	9281250	;
privAllo	[	0xE71FDA8eB295D2603704fC2b0994E483671c33B4	]	=	18562500	;
privAllo	[	0xf7dEa950Bbf1c17cd55c0E886Fb1811c54691770	]	=	14850000	;
privAllo	[	0xF803f4FF8A1647531aaA70B89cCC23Db3103A613	]	=	3712500	;
privAllo	[	0xf9381b5e6Ab94c2775d8a8F14C30B7d8C7FAa2a3	]	=	18562500	;
privAllo	[	0xFc4d1E48bF228346a39c6af3b78B19ECCA1cFC98	]	=	9281250	;
privAllo	[	0xfE33e3E48b1BA04708037B9Da2F0D4caD7A42dfb	]	=	9281250	;
privAllo	[	0xfF74F29B4A729E198093579D1e5E02A6DB903C39	]	=	9281250	;

    }

    modifier owner {
        require(isOwner[msg.sender] == true); _;
    }

    function _claim1_public(address user) public{
        require(hasClaimed_pub1[user] == false);
        uint amount = pubAllo[user];
        TOKEN.approve(address(this),amount);
        TOKEN.approve(msg.sender,amount);
        TOKEN.transferFrom(address(this),user,amount);
        hasClaimed_pub1[user] = true;
    }

    function _claim2_public(address user) public{
        require(hasClaimed_pub2[user] == false);
        uint amount = pubAllo[user];
        TOKEN.approve(address(this),amount);
        TOKEN.approve(msg.sender,amount);
        TOKEN.transferFrom(address(this),user,amount);
        hasClaimed_pub2[user] = true;
    }

    function _claim1_private(address user) public{
        require(hasClaimed_priv1[user] == false);
        uint amount = privAllo[user];
        TOKEN.approve(address(this),amount);
        TOKEN.approve(msg.sender,amount);
        TOKEN.transferFrom(address(this),user,amount);
        hasClaimed_priv1[user] = true;
    }

    function _claim2_private(address user) public{
        require(hasClaimed_priv2[user] == false);
        uint amount = privAllo[user];
        TOKEN.approve(address(this),amount);
        TOKEN.approve(msg.sender,amount);
        TOKEN.transferFrom(address(this),user,amount);
        hasClaimed_priv2[user] = true;
    }

    function _claim3_private(address user) public{
        require(hasClaimed_priv3[user] == false);
        uint amount = privAllo[user];
        TOKEN.approve(address(this),amount);
        TOKEN.approve(msg.sender,amount);
        TOKEN.transferFrom(address(this),user,amount);
        hasClaimed_priv3[user] = true;
    }

    function withdrawETH() public owner{
        uint contractBalance = address(this).balance;
        payable(msg.sender).transfer(contractBalance);
    }

    function withdrawTokens(address token) public owner{
        ERC20 _TOKEN = ERC20(token);
        uint contractBalance = _TOKEN.balanceOf(address(this));
        _TOKEN.approve(address(this),contractBalance);
        _TOKEN.approve(msg.sender,contractBalance);
        _TOKEN.transferFrom(address(this), msg.sender, contractBalance);
    }

    function setTOKEN(address token) public owner{
        suntoken = token; 
    }

    receive() external payable {}
    fallback() external payable {}

}