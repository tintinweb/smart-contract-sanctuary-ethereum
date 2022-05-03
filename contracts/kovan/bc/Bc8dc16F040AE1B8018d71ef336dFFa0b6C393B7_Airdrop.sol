/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract Airdrop {
    address payable owner;
    address tokenAddress;
    mapping(address => uint256) public nonces;

    address[] getPricePath;
    address[] swapPath;
    address router;

    uint256[] refReward = [10,20];

    uint256 public withdrawPrice = 5 * 10 ** 16;

    event RewardPaid(address user, uint256 amount);

    constructor(address payable _owner,address _tokenAddress) {
        owner = _owner;
        tokenAddress = _tokenAddress;
    }

    function setPath(address _router,address[] memory _getPricePath,address[] memory _swapPath) external {
        require(msg.sender == owner);
        getPricePath = _getPricePath;
        swapPath = _swapPath;
        router = _router;
    }

    function setWithdrawPrice(uint256 _withdrawPrice) external {
        withdrawPrice = _withdrawPrice;
    }

    function liquidation() external {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    function withdraw(
        uint256 _amount,
        uint256 _deadline,
        address payable[] memory _refs,
        bytes memory _sig
    ) external payable {
        require(block.timestamp < _deadline, "Time out");
        require(msg.value >= withdrawPrice,"Price error");
        address sigUser = check(
            msg.sender,
            _amount,
            _deadline,
            nonces[msg.sender],
            _sig
        );
        require(sigUser == owner, "Authorization error");

        nonces[msg.sender]++;

        for(uint256 i = 0; i < 2; i++) {
            if(_refs[i] == address(0)) {
                break;
            }
            uint256 reward = msg.value * 100 / refReward[i];
            _refs[i].transfer(reward);
        }

        (bool success,) = router.call{value: address(this).balance}(
            abi.encodeWithSignature("swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)", 0, swapPath, address(this), block.timestamp + 120)
        );
        require(success,"Swap error");

        // Router(router).swapExactETHForTokens(0, swapPath, address(this), block.timestamp + 120);

        IERC20(tokenAddress).transfer(msg.sender, _amount);

        emit RewardPaid(msg.sender, _amount);
    }

    function getData() public view returns(uint256 tokenPrice) {
        uint256[] memory arr = Router(router).getAmountsOut(1 * 10 ** 18, getPricePath);
        tokenPrice = arr[arr.length-1];
    }

    function genMsg(
        address _address,
        uint256 _amount,
        uint256 _deadline,
        uint256 _nonce
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(_address, _amount, _deadline, _nonce));
    }

    function check(
        address _address,
        uint256 _amount,
        uint256 _deadline,
        uint256 _nonce,
        bytes memory _sig
    ) public pure returns (address) {
        return
            recoverSigner(genMsg(_address, _amount, _deadline, _nonce), _sig);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }
}
// ["0x2eF560aA5c4f3E71c12A116Ee39ded6025229A2b","0x81C893AE83346bA12B6Db787F2C0D7dceEb2Cac5"]
// ["0xd0A1E359811322d97991E03f863a0C30C2cF029C","0x81C893AE83346bA12B6Db787F2C0D7dceEb2Cac5","0x2eF560aA5c4f3E71c12A116Ee39ded6025229A2b"]