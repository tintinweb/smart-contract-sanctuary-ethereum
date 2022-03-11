// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpCommon.sol";

import {AccountCenterInterface} from "../interfaces/IAccountCenter.sol";

contract OpClaimAaveV2StakedRewards is OpCommon {

    address public aaveIncentivesAddress;
    address public aaveStakeRewardClaimer;

    event LogAddr(address);

    constructor(address _aaveIncentivesAddress, address _aaveStakeRewardClaimer) {
        aaveIncentivesAddress = _aaveIncentivesAddress;
        aaveStakeRewardClaimer = _aaveStakeRewardClaimer;
    }

    function claimAaveStakeReward(address[] calldata atokens)
        public
        payable
    {
        require(msg.sender == address(aaveStakeRewardClaimer),"CHFRY: only AaveStakeRewardClaimer auth");
        for(uint256 i =0 ;i<atokens.length; i++){
            emit LogAddr(atokens[i]);
        }
        address EOA = AccountCenterInterface(accountCenter).getEOA(
            address(this)
        );

        // (bool success, ) = address(aaveIncentivesAddress).delegatecall(
        //     abi.encodeWithSignature(
        //         "claimRewards(address[],uint256,address)",
        //         atokens,
        //         type(uint256).max,
        //         EOA
        //     )
        // );
        // require(success == true, "CHFRY: claimRewards fail");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpCommon {
    // auth is shared storage with AccountProxy and any OpCode.
    mapping(address => bool) internal _auth;
    address internal accountCenter;

    receive() external payable {}

    modifier onlyAuth() {
        require(_auth[msg.sender], "CHFRY: Permission Denied");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccountCenterInterface {
    function accountCount() external view returns (uint256);

    function accountTypeCount() external view returns (uint256);

    function createAccount(uint256 accountTypeID)
        external
        returns (address _account);

    function getAccount(uint256 accountTypeID)
        external
        view
        returns (address _account);

    function getEOA(address account)
        external
        view
        returns (address payable _eoa);

    function isSmartAccount(address _address)
        external
        view
        returns (bool _isAccount);

    function isSmartAccountofTypeN(address _address, uint256 accountTypeID)
        external
        view
        returns (bool _isAccount);

    function getAccountCountOfTypeN(uint256 accountTypeID)
        external
        view
        returns (uint256 count);
}