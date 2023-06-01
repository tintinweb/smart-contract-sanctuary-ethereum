/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity ^0.8.0;
interface ERC20Mintable
{
    function mint(address to, uint256 amount) external;
    function MINTER_ROLE() external returns (bytes32);
    function hasRole(bytes32 role, address account) external returns (bool);
}

contract ERC20Check {
    using Counters for Counters.Counter;

    struct mintAmountInfo {
        uint256 totalAmount;
        uint256 availableAmount;
    }
    Counters.Counter private _id;
    struct ContractInfo {
        uint256 id;
        mapping (address => mintAmountInfo) minterInfos;
    }
    mapping (address => ContractInfo) public erc20Info;
    mapping (address => uint256[]) public userRegisteTokens;
    mapping (uint256 => address) public tokenIdAddrMaps;

    mapping (address => mapping (uint256 => uint256)) private userOwnMaps;  // account => erc20id => ownId

    struct Check {
        address tokenAddr;      // token contract address
        address issuerAddr;     // issuer's Check signing address
        address receiverAddr;   // receiver address
        uint256 beginId;        // begin id of the issued Check
        uint256 endId;          // end id of the issued Check
        uint256 amt;            // token amount in the Check
    }
    struct CurrentCheck {
        address tokenAddr;
        address receiverAddr;
        uint256 amt;
    }

    address private _admin;
    constructor(address admin) {
        _admin = admin;
        _id.increment();
    }

    function register(address tokenAddr, address issuerAddr, uint256 maxAmt) external {
        require(erc20Info[tokenAddr].id == 0, "token already exists");
        require(ERC20Mintable(tokenAddr).hasRole(ERC20Mintable(tokenAddr).MINTER_ROLE(), msg.sender) == true, "no minter role");
        
        erc20Info[tokenAddr].id = _id.current();
        erc20Info[tokenAddr].minterInfos[issuerAddr] = mintAmountInfo(maxAmt, maxAmt);

        userRegisteTokens[issuerAddr].push(erc20Info[tokenAddr].id);
        tokenIdAddrMaps[erc20Info[tokenAddr].id] = tokenAddr;

        _id.increment();
    }
    function addIssuerAmount(address tokenAddr, address issuerAddr, uint256 amt) external {
        require(erc20Info[tokenAddr].id > 0, "token not exists");
        require(ERC20Mintable(tokenAddr).hasRole(ERC20Mintable(tokenAddr).MINTER_ROLE(), msg.sender) == true, "no minter role");

        if (erc20Info[tokenAddr].minterInfos[issuerAddr].totalAmount > 0) {
            erc20Info[tokenAddr].minterInfos[issuerAddr].totalAmount += amt;
            erc20Info[tokenAddr].minterInfos[issuerAddr].availableAmount += amt;
        } else {
            erc20Info[tokenAddr].minterInfos[issuerAddr] = mintAmountInfo(amt, amt);
            userRegisteTokens[issuerAddr].push(erc20Info[tokenAddr].id);
        }
    }

    function getLastCheckId(address receiverAddr, address tokenAddr) public view returns (uint256) {
        require(erc20Info[tokenAddr].id > 0, "token not registed");
        return userOwnMaps[receiverAddr][erc20Info[tokenAddr].id];
    }
    function getLastCheckIdByTokens(address receiverAddr, address[] memory tokenAddrs) public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](tokenAddrs.length);
        for (uint256 i = 0; i < tokenAddrs.length; ++i) {
            ids[i] = getLastCheckId(receiverAddr, tokenAddrs[i]);
        }
        return ids;
    }

    function verifySign(address tokenAddr, address issuerAddr, address receiverAddr, uint256 beginId, uint256 endId, uint256 amt, uint8 v, bytes32 r, bytes32 s) internal view returns(address) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                tokenAddr,
                issuerAddr,
                receiverAddr,
                beginId,
                endId,
                amt
            )
        );
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return ecrecover(prefixedHash, v, r, s);
    }
    function mintToken(address tokenAddr, address issuerAddr, address receiverAddr, uint256 endId, uint256 mintAmt) internal {
        require(erc20Info[tokenAddr].id > 0, "mintToken: token not registed");
        require(erc20Info[tokenAddr].minterInfos[issuerAddr].availableAmount >= mintAmt, "mintToken: not enough available mint amount");

        ERC20Mintable(tokenAddr).mint(receiverAddr, mintAmt);
        userOwnMaps[receiverAddr][erc20Info[tokenAddr].id] = endId;
        erc20Info[tokenAddr].minterInfos[issuerAddr].availableAmount -= mintAmt;
    }
    
    function mint(Check[] memory checks, uint8[] memory v_issuer, bytes32[] memory r_issuer, bytes32[] memory s_issuer, uint8[] memory v_receiver, bytes32[] memory r_receiver, bytes32[] memory s_receiver) public {
        require(checks.length==v_issuer.length && checks.length==r_issuer.length && checks.length==s_issuer.length && checks.length==v_receiver.length && checks.length==r_receiver.length && checks.length==s_receiver.length, "Invalid input");

        require(checks[0].beginId == (getLastCheckId(checks[0].receiverAddr, checks[0].tokenAddr) + 1), "batchMint: start id not match");
        if (checks.length == 1) {
            require(verifySign(checks[0].tokenAddr, checks[0].issuerAddr, checks[0].receiverAddr, checks[0].beginId, checks[0].endId, checks[0].amt, v_issuer[0], r_issuer[0], s_issuer[0])==checks[0].issuerAddr, "Invalid signature admin");
            require(verifySign(checks[0].tokenAddr, checks[0].issuerAddr, checks[0].receiverAddr, checks[0].beginId, checks[0].endId, checks[0].amt, v_receiver[0], r_receiver[0], s_receiver[0])==checks[0].receiverAddr, "Invalid signature user");
            
            mintToken(checks[0].tokenAddr, checks[0].issuerAddr, checks[0].receiverAddr, checks[0].endId, checks[0].amt);
            return;
        }

        CurrentCheck memory check = CurrentCheck(checks[0].tokenAddr, checks[0].receiverAddr, checks[0].amt);
        for (uint256 i = 0; i < checks.length; i++) {
            require(verifySign(checks[i].tokenAddr, checks[i].issuerAddr, checks[i].receiverAddr, checks[i].beginId, checks[i].endId, checks[i].amt, v_issuer[i], r_issuer[i], s_issuer[i])==checks[i].issuerAddr, "Invalid signature admin");
            require(verifySign(checks[i].tokenAddr, checks[i].issuerAddr, checks[i].receiverAddr, checks[i].beginId, checks[i].endId, checks[i].amt, v_receiver[i], r_receiver[i], s_receiver[i])==checks[i].receiverAddr, "Invalid signature user");
            if (i > 0) {
                if (keccak256(abi.encodePacked(checks[i].tokenAddr))==keccak256(abi.encodePacked(check.tokenAddr)) && keccak256(abi.encodePacked(checks[i].receiverAddr))==keccak256(abi.encodePacked(check.receiverAddr))) {
                    require(checks[i].beginId == (checks[i-1].endId + 1), "batchMint: id is not continous");
                    check.amt += checks[i].amt;
                } else {
                    mintToken(check.tokenAddr, checks[i].issuerAddr, check.receiverAddr, checks[i-1].endId, check.amt);

                    check.tokenAddr = checks[i].tokenAddr;
                    check.receiverAddr = checks[i].receiverAddr;
                    require(checks[i].beginId == (getLastCheckId(check.receiverAddr, check.tokenAddr) + 1), "batchMint: start id not match");
                    check.amt = checks[i].amt;
                }
            }
            if (i == checks.length - 1) {
                mintToken(check.tokenAddr, checks[i].issuerAddr, check.receiverAddr, checks[i].endId, check.amt);
            }
        }
    }

    // total regist ERC20 counts
    function getHandledCount() public view returns (uint256) {
        return (_id.current() - 1);
    }
    function getTokenInfoByMinter(address tokenAddr, address issuerAddr) public view returns (uint256, uint256, uint256) {
        require(erc20Info[tokenAddr].id > 0, "Token not exist");
        if (erc20Info[tokenAddr].minterInfos[issuerAddr].totalAmount > 0) {
            return (erc20Info[tokenAddr].id, erc20Info[tokenAddr].minterInfos[issuerAddr].totalAmount, erc20Info[tokenAddr].minterInfos[issuerAddr].availableAmount);
        }
        return (erc20Info[tokenAddr].id, 0, 0);
    }
    function getRegisteredERC20s(address issuerAddr)view public returns(address[] memory) {
        address[] memory tokenAddrs = new address[](userRegisteTokens[issuerAddr].length);
        for (uint256 i = 0; i < userRegisteTokens[issuerAddr].length; ++i) {
            tokenAddrs[i] = tokenIdAddrMaps[userRegisteTokens[issuerAddr][i]];
        }
        return tokenAddrs;
    }
    
}