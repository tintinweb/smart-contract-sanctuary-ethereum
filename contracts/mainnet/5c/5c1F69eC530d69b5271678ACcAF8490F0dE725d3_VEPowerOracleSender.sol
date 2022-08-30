/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IAnycallV6Proxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function executor() external view returns (address);
}

interface IExecutor {
    function context() external returns (address from, uint256 fromChainID, uint256 nonce);
}

contract Administrable {
    address public admin;
    address public pendingAdmin;
    event LogSetAdmin(address admin);
    event LogTransferAdmin(address oldadmin, address newadmin);
    event LogAcceptAdmin(address admin);

    function setAdmin(address admin_) internal {
        admin = admin_;
        emit LogSetAdmin(admin_);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = pendingAdmin;
        pendingAdmin = newAdmin;
        emit LogTransferAdmin(oldAdmin, newAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit LogAcceptAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}

abstract contract AnyCallSender is Administrable {
    uint256 public flag; // 0: pay on dest chain, 2: pay on source chain
    address public anyCallProxy;

    mapping(uint256 => address) public receiver;

    modifier onlyExecutor() {
        require(msg.sender == IAnycallV6Proxy(anyCallProxy).executor());
        _;
    }

    constructor (address anyCallProxy_, uint256 flag_) {
        anyCallProxy = anyCallProxy_;
        flag = flag_;
    }

    function setReceivers(uint256[] memory chainIDs, address[] memory  receivers) public onlyAdmin {
        for (uint i = 0; i < chainIDs.length; i++) {
            receiver[chainIDs[i]] = receivers[i];
        }
    }

    function setAnyCallProxy(address proxy) public onlyAdmin {
        anyCallProxy = proxy;
    }

    function _anyCall(address _to, bytes memory _data, address _fallback, uint256 _toChainID) internal {
        if (flag == 2) {
            IAnycallV6Proxy(anyCallProxy).anyCall{value: msg.value}(_to, _data, _fallback, _toChainID, flag);
        } else {
            IAnycallV6Proxy(anyCallProxy).anyCall(_to, _data, _fallback, _toChainID, flag);
        }
    }
}

struct Point {
    int128 bias;
    int128 slope;
    uint ts;
    uint blk;
}

interface IVE {
    function ownerOf(uint _tokenId) external view returns (address);
    function balanceOfNFTAt(uint _tokenId, uint _t) external view returns (uint);
    function user_point_epoch(uint tokenId) external view returns (uint);
    function user_point_history(uint _tokenId, uint _idx) external view returns (Point memory);
}

contract VEPowerOracleSender is AnyCallSender {
    address public ve;
    uint256 public veEpochLength = 7257600;
    uint256 public daoChainID;

    event GrantVEPowerOracle(uint256 indexed ve_id, uint256 dao_id, uint256 power);

    constructor (address anyCallProxy_, uint256 flag_, address ve_, uint256 daoChainID_) AnyCallSender(anyCallProxy_, flag_) {
        setAdmin(msg.sender);
        ve = ve_;
        daoChainID = daoChainID_;
    }

    function currentEpoch() public view returns (uint256) {
        return block.timestamp / veEpochLength;
    }

    /// @notice delegateVEPower calculates average VE power in current epoch
    /// and send VE info to DAO chain
    /// @param ve_id ve tokenId
    /// @param dao_id dao id
    /// Receiver will update DAO user's VE point
    /// Receiver will prevent double granting
    function delegateVEPower(uint256 ve_id, uint256 dao_id) external payable {
        require(IVE(ve).ownerOf(ve_id) == msg.sender, "only ve owner");

        uint256 power = calcAvgVEPower(ve_id);
    
        bytes memory data = abi.encode(ve_id, dao_id, power, uint256(block.timestamp));
    
        _anyCall(receiver[daoChainID], data, address(this), daoChainID);
        emit GrantVEPowerOracle(ve_id, dao_id, power);
    }

    function calcAvgVEPower(uint256 ve_id) view public returns(uint256 avgPower) {
        uint t_0 = currentEpoch() * veEpochLength;
        uint interval = veEpochLength / 6;
        uint rand_i;
        uint p_i;
        uint t_i;
        uint sum_p;

        for (uint i = 0; i < 6; i++) {
            rand_i = uint256(keccak256(abi.encodePacked(i, ve_id, currentEpoch()))) % 1000;
            t_i = t_0 + i * interval + interval * rand_i / 1000;
            p_i = getPower(ve_id, t_i);
            sum_p += p_i;
        }

        return sum_p / 6;
    }

    function getPower(uint ve_id, uint t) view public returns (uint256 p) {
        int bias_0;
        uint pts_0;
        int bias_1;
        uint pts_1;
        uint userVEEpoch = IVE(ve).user_point_epoch(ve_id);

        if (t >= block.timestamp) {
            p = IVE(ve).balanceOfNFTAt(ve_id, t);
        } else {
            bias_1 = int(IVE(ve).balanceOfNFTAt(ve_id, block.timestamp));
            pts_1 = block.timestamp;
            Point memory point;

            for (uint idx = userVEEpoch; idx >= 0; idx--) {
                point = IVE(ve).user_point_history(ve_id, idx);
                if (point.ts >= t) {
                    bias_1 = point.bias;
                    pts_1 = point.ts;
                    if (pts_1 == 0) {
                        return 0;
                    }
                } else {
                    break;
                }
            }
            bias_0 = int256(point.bias);
            pts_0 = point.ts;
            p = uint256(int256(pts_1 - t) / int256(pts_1 - pts_0) * (bias_0 - bias_1) + bias_1);
        }
        return p;
    }
}