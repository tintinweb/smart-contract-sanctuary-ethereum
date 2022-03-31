/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Compatible {
    function transfer(address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint _value) external;
    function balanceOf(address _owner) external view returns (uint balance);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function balanceOf(address guy) external view returns (uint balance);
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

interface IChiToken is IERC20 {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256);
    function freeUpTo(uint256 value) external returns (uint256);
    function freeFrom(address from, uint256 value) external returns (uint256);
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
}

contract TradingVault {

    IChiToken constant chi = IChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    IWETH constant wtok = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    modifier discountGas(uint8 burn) {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        if (burn != 0 && gasSpent > 50000) {
            chi.freeUpTo( (((gasSpent + 14154) / 41947) * uint256(burn)) / 0xFF );
        }
    }

    modifier onlyOwner() {
        require(0xaaAAAEB932C0527655BaFF3bBbE3264bc61271E8 == msg.sender || 0xAaaaAf4bf78E014Af3a25DBc702e7493FB3b98c8 == msg.sender || 0xaAaAA22233Cf3A2eEfACB085F5E2d828fB47f458 == msg.sender || 0xaaAAa85601E05dfA39cf4A0A037dD371A0db8887 == msg.sender || 0xAAAaA29A382baa888655841a3d9af997044fC8c9 == msg.sender || 0xAAAAA0bfA6A92ad1531B2Aa438BDDdF50DCA7Ee2 == msg.sender || 0xaAAAA319f89a58F7e0CfD2C86F2D7047aa0c32D7 == msg.sender || 0xAaaaADDd3f56601bC5BE6DD1e2655F9029531788 == msg.sender || 0xaaaaA3F91B2D4b714526D0096485fa34B63F8807 == msg.sender || 0xAaaAaf4acD6e97219e35A807Aab2c041283DF5fe == msg.sender || 0xaaAAA6fF8986A294E5A817187921Ae47BddFbFF4 == msg.sender || 0xAAaAa328bd652D0cB9E7A112476FC1AFF458a9C4 == msg.sender || 0xAaAaA2789CDc3c97C1dCe79AC1a1A163f014d882 == msg.sender || 0xAAAaA3A7370D91A983067503573a55A2BC3EC1ca == msg.sender || 0xaaAAab018316f37951E2894585C160514F495582 == msg.sender || 0xAAaaaD2B13Cf538D5295c53c65Acb7185036D0c8 == msg.sender, "NS");
        _;
    }

    constructor() {
    }

    function withdrawEther(uint256 amount, address payable to) public onlyOwner {
        to.transfer(amount);
    }

    function depositEther(uint256 amount) public onlyOwner {
        if (amount == 0) {
            wtok.deposit{value: address(this).balance}();
        } else {
            wtok.deposit{value: amount}();
        }
    }

    function withdrawToken(address token, uint256 amount, address to) public onlyOwner {
        IERC20Compatible erc20token = IERC20Compatible(token);
        erc20token.transfer(to, amount);
    }

    function refill(uint256 totAmount, uint256[] calldata amounts, address payable[] calldata to, uint8 burn) external onlyOwner discountGas(burn) {
        wtok.withdraw(totAmount);
        for (uint i = 0; i < amounts.length; i++) {
            to[i].transfer(amounts[i]);
        }
    }

    function multiCall(address[] calldata impls, bytes[] calldata data, uint8 burn) external onlyOwner discountGas(burn) payable {
        for (uint256 i = 0; i < impls.length; i++) {
            (bool success, bytes memory result) = impls[i].delegatecall(data[i]);
            if (!success) {
                revert(_getRevertMsg(result));
            }
        }
    }

    function singleCall(address impl, bytes calldata data, uint8 burn) external onlyOwner discountGas(burn) payable {
        (bool success, bytes memory result) = impl.delegatecall(data);
        if (!success) {
            revert(_getRevertMsg(result));
        }
    }

    // https://ethereum.stackexchange.com/a/83577
    function _getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'ER';
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    fallback() external {
        require(false, "FB");
    }

    receive () payable external {
    }
}