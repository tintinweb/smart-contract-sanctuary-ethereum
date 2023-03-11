/*
    Copyright 2021 Project Galaxy.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {Address} from "Address.sol";
import {SafeMath} from "SafeMath.sol";
import {IERC20} from "IERC20.sol";
import {EIP712} from "EIP712.sol";
import {ECDSA} from "ECDSA.sol";
import {IStarNFT} from "IStarNFT.sol"; //0.7.6

/**
 * @title SpaceStation
 * @author Galaxy Protocol
 *
 * Campaign contract that allows privileged DAOs to initiate campaigns for members to claim StarNFTs.
 */
contract SpaceStationV2 is EIP712 {
    using Address for address;
    using SafeMath for uint256;

    /* ============ Events ============ */
    event EventActivateCampaign(uint256 _cid);
    event EventClaim(
        uint256 _cid,
        uint256 _dummyId,
        uint256 _nftID,
        IStarNFT _starNFT,
        address _sender
    );
    event EventClaimCapped(
        uint256 _cid,
        uint256 _dummyId,
        uint256 _nftID,
        IStarNFT _starNFT,
        address _sender,
        uint256 _minted,
        uint256 _cap
    );
    event EventClaimBatch(
        uint256 _cid,
        uint256[] _dummyIdArr,
        uint256[] _nftIDArr,
        IStarNFT _starNFT,
        address _sender
    );
    event EventClaimBatchCapped(
        uint256 _cid,
        uint256[] _dummyIdArr,
        uint256[] _nftIDArr,
        IStarNFT _starNFT,
        address _sender,
        uint256 _minted,
        uint256 _cap
    );
    event EventForge(
        uint256 _cid,
        uint256 _dummyId,
        uint256 _nftID,
        IStarNFT _starNFT,
        address _sender
    );

    /* ============ Modifiers ============ */
    /**
     * Throws if the sender is not a campaign setter, gnosis
     */
    modifier onlyCampaignSetter() {
        _validateOnlyCampaignSetter();
        _;
    }
    /**
     * Throws if the sender is not a manager: pauser_role and upgrader_role, gnosis
     */
    modifier onlyManager() {
        _validateOnlyManager();
        _;
    }
    /**
     * Throws if the sender is not a Treasury's manager, gnosis safe
     */
    modifier onlyTreasuryManager() {
        _validateOnlyTreasuryManager();
        _;
    }
    /**
     * Throws if the contract paused
     */
    modifier onlyNoPaused() {
        _validateOnlyNotPaused();
        _;
    }

    /* ============ Enums ================ */

    /* ============ Structs ============ */

    struct CampaignFeeConfig {
        address erc20; // Address of token asset if required
        uint256 erc20Fee; // Amount of token if required
        uint256 platformFee; // Amount of fee for using the service if applicable
    }

    /* ============ State Variables ============ */
    // Is contract paused.
    bool public paused;

    // The galaxy signer(EOA): used to verify EIP-712.
    address public galaxy_signer;
    // A campaign setter. TODO: mapping of EOAs to reduce multisig tx gas cost.
    address public campaign_setter;
    // The manager which has privilege to do upgrades, pause/unpause.
    address public manager;
    // Treasury manager which receives fees.
    address public treasury_manager;

    // Mapping that stores all fee requirements for a given activated campaign.
    // If no fee is required at all, should set to all zero values except for `isActive`.
    mapping(uint256 => CampaignFeeConfig) public campaignFeeConfigs;
    // hasMinted(dummyID(signature) => bool) that records if the user account has already used the dummyID(signature).
    mapping(uint256 => bool) public hasMinted;
    // for capped campaign usage only
    mapping(uint256 => uint256) public numMinted;

    /* ============ Constructor ============ */
    constructor(
        address _galaxy_signer,
        address _campaign_setter,
        address _contract_manager,
        address _treasury_manager
    ) EIP712("Galaxy", "1.0.0") {
        // require(galaxy_signer != address(0), "Galaxy signer address must not be null address");
        // require(campaign_setter != address(0), "Campaign setter address must not be null address");
        // require(contract_manager != address(0), "Contract manager address must not be null address");
        // require(treasury_manager != address(0), "Treasury manager address must not be null address");
        galaxy_signer = _galaxy_signer;
        campaign_setter = _campaign_setter;
        manager = _contract_manager;
        treasury_manager = _treasury_manager;
    }

    /* ============ External Functions ============ */
    function activateCampaign(
        uint256 _cid,
        uint256 _platformFee,
        uint256 _erc20Fee,
        address _erc20
    ) external onlyCampaignSetter {
        _setFees(_cid, _platformFee, _erc20Fee, _erc20);
        emit EventActivateCampaign(_cid);
    }

    function claim(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256 _dummyId,
        uint256 _powah,
        address _mintTo,
        bytes calldata _signature
    ) public payable onlyNoPaused {
        require(!hasMinted[_dummyId], "Already minted");
        require(
            _verify(
                _hash(_cid, _starNFT, _dummyId, _powah, _mintTo),
                _signature
            ),
            "Invalid signature"
        );
        hasMinted[_dummyId] = true;
        _payFees(_cid, 1);
        uint256 nftID = _starNFT.mint(_mintTo, _powah);
        emit EventClaim(_cid, _dummyId, nftID, _starNFT, _mintTo);
    }

    function claim(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256 _dummyId,
        uint256 _powah,
        bytes calldata _signature
    ) external payable onlyNoPaused {
        claim(_cid, _starNFT, _dummyId, _powah, msg.sender, _signature);
    }

    function claimBatch(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _dummyIdArr,
        uint256[] calldata _powahArr,
        address _mintTo,
        bytes calldata _signature
    ) public payable onlyNoPaused {
        require(
            _dummyIdArr.length > 0,
            "Array(_dummyIdArr) should not be empty"
        );
        require(
            _powahArr.length == _dummyIdArr.length,
            "Array(_powahArr) length mismatch"
        );

        for (uint256 i = 0; i < _dummyIdArr.length; i++) {
            require(!hasMinted[_dummyIdArr[i]], "Already minted");
            hasMinted[_dummyIdArr[i]] = true;
        }

        require(
            _verify(
                _hashBatch(_cid, _starNFT, _dummyIdArr, _powahArr, _mintTo),
                _signature
            ),
            "Invalid signature"
        );
        _payFees(_cid, _dummyIdArr.length);

        uint256[] memory nftIdArr = _starNFT.mintBatch(
            _mintTo,
            _powahArr.length,
            _powahArr
        );
        emit EventClaimBatch(_cid, _dummyIdArr, nftIdArr, _starNFT, _mintTo);
    }

    function claimBatch(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _dummyIdArr,
        uint256[] calldata _powahArr,
        bytes calldata _signature
    ) external payable onlyNoPaused {
        claimBatch(_cid, _starNFT, _dummyIdArr, _powahArr, msg.sender, _signature);
    }

    function claimCapped(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256 _dummyId,
        uint256 _powah,
        uint256 _cap,
        address _mintTo,
        bytes calldata _signature
    ) public payable onlyNoPaused {
        require(!hasMinted[_dummyId], "Already minted");
        require(numMinted[_cid] < _cap, "Reached cap limit");
        require(
            _verify(
                _hashCapped(_cid, _starNFT, _dummyId, _powah, _cap, _mintTo),
                _signature
            ),
            "Invalid signature"
        );
        hasMinted[_dummyId] = true;
        numMinted[_cid] = numMinted[_cid] + 1;
        _payFees(_cid, 1);
        uint256 nftID = _starNFT.mint(_mintTo, _powah);
        uint256 minted = numMinted[_cid];
        emit EventClaimCapped(_cid, _dummyId, nftID, _starNFT, _mintTo, minted, _cap);
    }

    function claimCapped(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256 _dummyId,
        uint256 _powah,
        uint256 _cap,
        bytes calldata _signature
    ) external payable onlyNoPaused {
        claimCapped(_cid, _starNFT, _dummyId, _powah, _cap, msg.sender, _signature);
    }

    function claimBatchCapped(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _dummyIdArr,
        uint256[] calldata _powahArr,
        uint256 _cap,
        address _mintTo,
        bytes calldata _signature
    ) public payable onlyNoPaused {
        require(
            _dummyIdArr.length > 0,
            "Array(_dummyIdArr) should not be empty"
        );
        require(
            _powahArr.length == _dummyIdArr.length,
            "Array(_powahArr) length mismatch"
        );
        require(
            numMinted[_cid] + _dummyIdArr.length <= _cap,
            "Reached cap limit"
        );

        for (uint256 i = 0; i < _dummyIdArr.length; i++) {
            require(!hasMinted[_dummyIdArr[i]], "Already minted");
            hasMinted[_dummyIdArr[i]] = true;
        }

        require(
            _verify(
                _hashBatchCapped(
                    _cid,
                    _starNFT,
                    _dummyIdArr,
                    _powahArr,
                    _cap,
                    _mintTo
                ),
                _signature
            ),
            "Invalid signature"
        );
        numMinted[_cid] = numMinted[_cid] + _dummyIdArr.length;
        _payFees(_cid, _dummyIdArr.length);
        uint256[] memory nftIdArr = _starNFT.mintBatch(
            _mintTo,
            _powahArr.length,
            _powahArr
        );
        uint256 minted = numMinted[_cid];
        emit EventClaimBatchCapped(_cid, _dummyIdArr, nftIdArr, _starNFT, _mintTo, minted, _cap);
    }

    function claimBatchCapped(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _dummyIdArr,
        uint256[] calldata _powahArr,
        uint256 _cap,
        bytes calldata _signature
    ) external payable onlyNoPaused {
        claimBatchCapped(_cid, _starNFT, _dummyIdArr, _powahArr, _cap, msg.sender, _signature);
    }

    function forge(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _nftIDs,
        uint256 _dummyId,
        uint256 _powah,
        address _mintTo,
        bytes calldata _signature
    ) public payable onlyNoPaused {
        require(!hasMinted[_dummyId], "Already minted");
        require(
            _verify(
                _hashForge(
                    _cid,
                    _starNFT,
                    _nftIDs,
                    _dummyId,
                    _powah,
                    _mintTo
                ),
                _signature
            ),
            "Invalid signature"
        );
        hasMinted[_dummyId] = true;
        for (uint256 i = 0; i < _nftIDs.length; i++) {
            require(
                _starNFT.isOwnerOf(_mintTo, _nftIDs[i]),
                "Not the owner"
            );
        }
        _starNFT.burnBatch(_mintTo, _nftIDs);
        _payFees(_cid, 1);
        uint256 nftID = _starNFT.mint(_mintTo, _powah);
        emit EventForge(_cid, _dummyId, nftID, _starNFT, _mintTo);
    }

    function forge(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _nftIDs,
        uint256 _dummyId,
        uint256 _powah,
        bytes calldata _signature
    ) external payable onlyNoPaused {
        forge(_cid, _starNFT, _nftIDs, _dummyId, _powah, msg.sender, _signature);
    }

    receive() external payable {
        // anonymous transfer: to treasury_manager
        (bool success, ) = treasury_manager.call{value: msg.value}(
            new bytes(0)
        );
        require(success, "Transfer failed");
    }

    fallback() external payable {
        if (msg.value > 0) {
            // call non exist function: send to treasury_manager
            (bool success, ) = treasury_manager.call{value: msg.value}(new bytes(0));
            require(success, "Transfer failed");
        }
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Function that update galaxy signer address.
     */
    function updateGalaxySigner(address newAddress) external onlyManager {
        require(
            newAddress != address(0),
            "Galaxy signer address must not be null address"
        );
        galaxy_signer = newAddress;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Function that update galaxy signer address.
     */
    function updateCampaignSetter(address newAddress) external onlyManager {
        require(
            newAddress != address(0),
            "Campaign setter address must not be null address"
        );
        campaign_setter = newAddress;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Function that update manager address.
     */
    function updateManager(address newAddress) external onlyManager {
        require(
            newAddress != address(0),
            "Manager address must not be null address"
        );
        manager = newAddress;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Function that update treasure manager address.
     */
    function updateTreasureManager(address payable newAddress)
    external
    onlyTreasuryManager
    {
        require(
            newAddress != address(0),
            "Treasure manager must not be null address"
        );
        treasury_manager = newAddress;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Function that pause the contract.
     */
    function setPause(bool _paused) external onlyManager {
        paused = _paused;
    }

    /* ============ Internal Functions ============ */
    function _hash(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256 _dummyId,
        uint256 _powah,
        address _account
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(uint256 cid,address starNFT,uint256 dummyId,uint256 powah,address account)"
                    ),
                    _cid,
                    _starNFT,
                    _dummyId,
                    _powah,
                    _account
                )
            )
        );
    }

    function _hashCapped(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256 _dummyId,
        uint256 _powah,
        uint256 _cap,
        address _account
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(uint256 cid,address starNFT,uint256 dummyId,uint256 powah,uint256 cap,address account)"
                    ),
                    _cid,
                    _starNFT,
                    _dummyId,
                    _powah,
                    _cap,
                    _account
                )
            )
        );
    }

    function _hashBatch(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _dummyIdArr,
        uint256[] calldata _powahArr,
        address _account
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(uint256 cid,address starNFT,uint256[] dummyIdArr,uint256[] powahArr,address account)"
                    ),
                    _cid,
                    _starNFT,
                    keccak256(abi.encodePacked(_dummyIdArr)),
                    keccak256(abi.encodePacked(_powahArr)),
                    _account
                )
            )
        );
    }

    function _hashBatchCapped(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _dummyIdArr,
        uint256[] calldata _powahArr,
        uint256 _cap,
        address _account
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(uint256 cid,address starNFT,uint256[] dummyIdArr,uint256[] powahArr,uint256 cap,address account)"
                    ),
                    _cid,
                    _starNFT,
                    keccak256(abi.encodePacked(_dummyIdArr)),
                    keccak256(abi.encodePacked(_powahArr)),
                    _cap,
                    _account
                )
            )
        );
    }

    // todo: change to internal on PRD
    function _hashForge(
        uint256 _cid,
        IStarNFT _starNFT,
        uint256[] calldata _nftIDs,
        uint256 _dummyId,
        uint256 _powah,
        address _account
    ) public view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFT(uint256 cid,address starNFT,uint256[] nftIDs,uint256 dummyId,uint256 powah,address account)"
                    ),
                    _cid,
                    _starNFT,
                    keccak256(abi.encodePacked(_nftIDs)),
                    _dummyId,
                    _powah,
                    _account
                )
            )
        );
    }

    // todo: change to internal on PRD
    function _verify(bytes32 hash, bytes calldata signature)
    public
    view
    returns (bool)
    {
        return ECDSA.recover(hash, signature) == galaxy_signer;
    }

    function _setFees(
        uint256 _cid,
        uint256 _platformFee,
        uint256 _erc20Fee,
        address _erc20
    ) private {
        require(
            (_erc20 == address(0) && _erc20Fee == 0) ||
            (_erc20 != address(0) && _erc20Fee != 0),
            "Invalid erc20 fee requirement arguments"
        );
        campaignFeeConfigs[_cid] = CampaignFeeConfig(
            _erc20,
            _erc20Fee,
            _platformFee
        );
    }

    function _payFees(uint256 _cid, uint256 amount) private {
        require(amount > 0, "Must mint more than 0");
        CampaignFeeConfig memory feeConf = campaignFeeConfigs[_cid];
        // 1. pay platformFee if needed
        if (feeConf.platformFee > 0) {
            require(
                msg.value >= feeConf.platformFee.mul(amount),
                "Insufficient Payment"
            );
            (bool success, ) = treasury_manager.call{value: msg.value}(
                new bytes(0)
            );
            require(success, "Transfer platformFee failed");
        }
        // 2. pay erc20_fee if needed
        if (feeConf.erc20Fee > 0) {
            // user wallet transfer <erc20> of <feeConf.erc20Fee> to <this contract>.
            require(
                IERC20(feeConf.erc20).transferFrom(
                    msg.sender,
                    treasury_manager,
                    feeConf.erc20Fee.mul(amount)
                ),
                "Transfer erc20Fee failed"
            );
        }
    }

    /**
     * Due to reason error bloat, internal functions are used to reduce bytecode size
     */
    function _validateOnlyCampaignSetter() internal view {
        require(msg.sender == campaign_setter, "Only campaignSetter can call");
    }

    function _validateOnlyManager() internal view {
        require(msg.sender == manager, "Only manager can call");
    }

    function _validateOnlyTreasuryManager() internal view {
        require(
            msg.sender == treasury_manager,
            "Only treasury manager can call"
        );
    }

    function _validateOnlyNotPaused() internal view {
        require(!paused, "Contract paused");
    }
}