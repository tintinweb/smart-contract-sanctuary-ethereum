/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

//SPDX-License-Identifier: MIT


/*
     Klee Claim for V2

*/

pragma solidity ^0.8.6;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory  errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory  errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract kleeClaim {


    address owner;
    mapping(address => bool) banned;
    mapping (address => uint256) public _balances;
    

    constructor() {
        owner = msg.sender;
     
        banned[0x7E47B50B95d16e1b5A80586eeDDbb3c561907611]= true;
        banned[0xC64e0Ca5A7C46e3B418c643C4F7AA6711261AffC]= true;
        banned[0xA41000C7faF8dc1626cc332A1F5E98C9466691A5]= true;
        banned[0xE5B8ff1ca1c3Ef2ac704783d6473Ee5a9BE7e02d]= true;
        banned[0x0c93C1860C5BacF7015701e80CdC4c4CDEbC39c2]= true;
        banned[0x6f47d53b62D1f28C49CE939D1f5655f81F8A48E1]= true;
        banned[0xf67d4d639448Cd37b0f5ca3CED04433963f625fD]= true;
        banned[0x983FCB1345BE0143FCAD9ed4E52284067F342a9C]= true;
        banned[0xB20bF6D7f60059dd5dE46F3F0F32665a259ea6C0]= true;
        banned[0xd68b57e44B6bD4b2512fC75E489eba671A8E449f]= true;
        banned[0x4768c3CD39723178A039dd3fc6EA1470Bae7c385]= true;
        banned[0xD9ce9aEC92f3dA9Bf4875023F19fA4F68742a401]= true;
        banned[0xd585B5906264795D7F3e9a2cc6969bA849Bb9bB8]= true;
        banned[0x0203eDf96D47925ed319188e2B150A7abAA068c5]= true;
        banned[0xE23baA92776419fA239CbB92Ad5Db3945b0A6260]= true;
        banned[0x12a2b0Ca9DEbf08E3a2b0C68184b2d7c7DDF4dC2]= true;
        banned[0x57c96e36230a558b34eF4585B3bD4D27FffceACA]= true;
        banned[0x174Ae5a36f5dd7591615E96f158614723a4D8E4E]= true;
        banned[0x0B1D479D57D9Faa62Efb29762d0EE9B0Ef4B323b]= true;
        banned[0x93b0fE68222B5fdC711BF7f82809Ab6D38c85C1f]= true;
        banned[0x2B0362f2C5e49CDDc0B72353661bce783Ce5973E]= true;
        banned[0xd94A906f40002E68974Fb75c2f30303ab57a91Ce]= true;
        banned[0x04450499a50b117E3deC3F44cFc46318781Da5eF]= true;
        banned[0xb79f2924A0d805082A0e1C131D1bDc73dBE1ADee]= true;
        banned[0x0000000000D9455CC7EB92D06E00582A982f68fe]= true;
        banned[0x5f62593C70069AbB35dFe2B63db969e8906609d6]= true;
        banned[0xA929F030458Be505749Fc8eC8C3941225D6d1532]= true;
        banned[0x30998E68E9f2A532131F69811fBB88870aa0389F]= true;
        banned[0x9b19858616Abba3525c99A2B09B1C0F2F02d0179]= true;
        banned[0x731Ea79A1B2B90683507Da2aaB498bd8fF8f7ff1]= true;
        banned[0xfeCd0eF07223D35a79BaAD451b31A4Ad73Fa72e4]= true;
        banned[0x308e78BF7848863bF75A1EB93bbD2B64Da7DA2c5]= true;
        banned[0x00000000003b3cc22aF3aE1EAc0440BcEe416B40]= true;
        banned[0x82B771E9F2F9B92B4B8f4EBDA4aeB60d3040d6Dc]= true;
        banned[0xE8c060F8052E07423f71D445277c61AC5138A2e5]= true;
        banned[0x6a06A7f368dd9c57DE34B0F725709E8939b9BeC1]= true;
        banned[0x931b23DaC01EF88BE746d752252D831464a3834C]= true;
        banned[0x2Cfcbd233268C302996c767347eb45bec36FB08D]= true;
        banned[0x220bdA5c8994804Ac96ebe4DF184d25e5c2196D4]= true;
        banned[0x19801f0647f12DdBbB265f3BAF5bdFE6386bD2B7]= true;
        banned[0x05B5952da949F25368a5473D3D59B5aC73FaD486]= true;
        banned[0x3Ed75618518B9D015d37A151b7a61dc1E79Ab49B]= true;
        banned[0xC1dfd16259C2530e57aEa8A2cF106db5671616B0]= true;
        banned[0xA268C06B5AA8B5C1EFCc0389F7b255DaE3Fa9323]= true;
        banned[0xe0a9efE32985cC306255b395a1bd06D21ccEAd42]= true;
        banned[0x9522B04D51983f669Bea38A5C6871e98a12E895f]= true;
        banned[0x29a7f67A3F990ECbC9cFa2A94422CC644f396c80]= true;
        banned[0x081D6316E9832700F7f1C4e3Eb26Fd8a047c86f6]= true;
        banned[0x65463d202179AE0f2Aaa0FF58BEe3096Dcc78A5a]= true;
        banned[0xFE52607e1482Fe634Fd82Ca82d74f12990d3dcBd]= true;
        banned[0x07888c3C5D25fa74AE04A9EaD1fB1cF0E7743689]= true;
        banned[0x0B741b593b891A12116372e78838a7E031884db0]= true;
        banned[0x0B3DE409a3CC76C68d4d49d280D8A03a74Ad8383]= true;
        banned[0xDFC43D46410cd1f3872ac2761adf6878f23c87a8]= true;
        banned[0xE7C7611b8e053b7F1b315c6Aa9Abad0Abc008891]= true;
        banned[0xb307F5Bb82efB174B190fe5c850c59ef8b2Ec936]= true;
        banned[0xD13B2e65eCb2fAE93169BF91432864A5Da5FCA8C]= true;
        banned[0x9c22cebB76ed68d241e2515D3fC0B0500C7Cb4b7]= true;
        banned[0x2D7fd3D6aC1f67CB3012b40028Bee5f5A7b9e19A]= true;
        banned[0xCe584ef141129d78641B490433CaE2fC1AC5bE05]= true;
        banned[0xCe41DEd99eb6dE32Ef7eD76d5D2F9DfF0778c81F]= true;
        banned[0x870727673AF0B5c68D1b940DEa139752d96bBC60]= true;
        banned[0x57aE5a6837f6e0d0EEB9814b6eA42Ad165fd9C0e]= true;
        banned[0xF570b31E75740f24a6cb89801F7170859AF86E91]= true;
        banned[0x3F4Ad062F4D567dEb7fEeb48CdeCFEeDaeb81829]= true;
        banned[0xC4b4F657f7423D0535c9C77d709e605FE59C1758]= true;
        banned[0xaeB8f8C0b2f228eD7EB43e2301C50a6B35113b22]= true;
        banned[0x5a5C953805ff7E26986eFE92814BF3b07B049F3a]= true;
        banned[0x8BF1C20eCB5ad8d51f23C1AAc4D334A50dC36F0E]= true;
        banned[0xe033480D7d808f41573C321c5Ab3f4100aF15CFA]= true;
        banned[0x9D109CE0592a3c55E169fAC849D304B37fEfbFd3]= true;
        banned[0x3B94f4585fFF1662bC001663f276CFDd33A032BD]= true;
        banned[0x96Da549f4464947759704b719Cd0D57b5b3aA345]= true;
        banned[0x4eBd211696ecD8D8b907c0f9F243ea926A19b636]= true;
        banned[0x79ed0B975A095914a69cb97a3fc2e5432408f601]= true;
        banned[0xc9a5ec9e1A950794Bf69B34d07947EB2E9664bfc]= true;
        banned[0xE0a616C3659bE29567E08819772e6905307AdF21]= true;
        banned[0x2045862499229570D8Ca1548dAE6087eFAb57F0E]= true;
        banned[0x5961cDbBe665C8094BFBC9D888B21B82378f981a]= true;
        banned[0xD1f9Cf2753a5A442d8DD47DE6142b4E9B6F4b1A5]= true;
        banned[0xAC1C51c08621fc84E10E9D246642d1C69833d810]= true;
        banned[0xc066A76701fD2Bc6b6c052F51d71B63275525B9c]= true;
        banned[0x865D8cce369dDE678943Ab58d02445911725099A]= true;
        banned[0x40dFfa04c2f49ec6e5aF0A11Ed30731065ceC0De]= true;
        banned[0xC88b5277Cda867dB35f4D118A60C74d0eE11138C]= true;
        banned[0x02b7FAF716019f98d78e7a06F9606ef5522673bB]= true;
        banned[0x4d944a25bC871D6C6EE08baEf0b7dA0b08E6b7b3]= true;
        banned[0x08D0B9AA7121f5B70f1109eBD4b04b18A6322FC7]= true;
        banned[0x277ccfaB0C990705ED6e59F8E2A589a61679ffEd]= true;
        banned[0xaf048Bc3e1EEb3EF5a4345E1a497274B1177B8c5]= true;
        banned[0x66E70f6812a1567681127ca56d46Cb51AceCA316]= true;
        banned[0x1c68E43890FEf21cd43f764150fff4121773e22d]= true;
        banned[0x54d6A53E6133C3a1B6B4C467e2344529e1D495B9]= true;
        banned[0xdd62fC4fF41801B0A65955ccAA35B46abC735D80]= true;
        banned[0x84061a7F23F558a3552617bC204C435BC4a9d0DA]= true;
        banned[0x9Bde1CECB101BE673B07383e0244821cc6b4F222]= true;
        banned[0xcab12a4dC4D36f91C794d89b02db6457D2777f69]= true;
        banned[0xc0FA1e4667Bc585b52371B4194b7ADB555359CdA]= true;
        banned[0x4d21509DF723f9d09364012798b6dc777Fc717cc]= true;
        banned[0xE5B8ff1ca1c3Ef2ac704783d6473Ee5a9BE7e02d]= true;
        banned[0xE356fe28B7B6B015a3b2BB4419dBdF2777d7420B]= true;
}



    IERC20 klee = IERC20(0x382f0160c24f5c515A19f155BAc14d479433A407);
    IERC20 newKlee = IERC20(0xA67E9F021B9d208F7e3365B2A155E3C55B27de71);

    bool locked;
    bool open;


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


  modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

 event Transfer(address indexed from, address indexed to, uint256 value);

   bool public claim_enable;
    mapping(address => bool) public claimed;
     address[] public claimed_list;


      function MIGRATION_control_claim(bool booly) public onlyOwner {
        claim_enable = booly;
    }

  function MIGRATION_approve_v1() public safe {
        
        uint to_give = klee.balanceOf(msg.sender);
        require(to_give > 0, "No tokens to transfer");
        require(klee.allowance(msg.sender, address(this)) <= to_give, "Already enough allowance");
        klee.approve(address(this), to_give*10);
    }
   

     function claim_v2() public safe {
       uint to_give = klee.balanceOf(msg.sender);
        require(_balances[address(this)] >= to_give, "Not enough tokens!");
        require(!claimed[msg.sender], "go away");
        newKlee.transfer(msg.sender, to_give);
        claimed[msg.sender] = true;
        claimed_list.push(msg.sender);
    }

    function MIGRATION_allowance_on_v1(address addy) public view onlyOwner returns (uint allowed, uint balance) {
        return (klee.allowance(addy, address(this)), klee.balanceOf(addy));
    }


   function MIGRATION_has_claimed(address addy) public view returns(bool has_it) {
        return(claimed[addy]);
    }


    function set_address(address addy) public onlyOwner {
        newKlee = IERC20(addy);
    }

    function ban(address addy) public onlyOwner {
        banned[addy] = true;
    }

    
    function unban(address addy) public onlyOwner {
        banned[addy] = false;
    }

    function open_claim(bool booly) public onlyOwner {
        open = booly;
    }


    function retire(address addy) public onlyOwner {
        IERC20 tkn = IERC20(addy);
        tkn.transfer(msg.sender, tkn.balanceOf(address(this)));
    }

      function rescueTokens(address addy) public onlyOwner {
        IERC20 token = IERC20(addy);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance>0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }


    
    receive() external payable {}
    fallback() external payable {}

}