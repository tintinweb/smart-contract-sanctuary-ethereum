/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IPoLidoNFT {
    /// @notice List all the tokens owned by an address.
    /// @param _owner the owner address.
    /// @return result return a list of token ids.
    function getOwnedTokens(address _owner) external view returns (uint256[] memory);  
}

interface IStMaticTool{
    struct RequestWithdraw {
        uint256 amount2WithdrawFromStMATIC;
        uint256 validatorNonce;
        uint256 requestEpoch;
        address validatorAddress;
    }
}




interface IstMatic is IStMaticTool{
    function getToken2WithdrawRequests(uint256 _tokenId) external view returns (RequestWithdraw[] memory);
    function getMaticFromTokenId(uint256 _tokenId) external view returns (uint256);
    function nodeOperatorRegistry() external view returns(address);
    function getTotalPooledMatic() external view returns (uint256);
    function convertStMaticToMatic(uint256 _amountInStMatic) external view returns (uint256 amountInMatic, uint256 totalStMaticAmount, uint256 totalPooledMatic);
    function totalBuffered() external view returns(uint256);
    function reservedFunds() external view returns(uint256);
    function token2WithdrawRequest(uint256 _tokenId) external view returns (RequestWithdraw memory);
}

interface IstakeManger{
    function currentEpoch() external view returns(uint256);
}


interface INodeOperatorRegistry {
    /// @notice The node operator struct
    /// @param validatorShare the validator share address of the validator.
    /// @param rewardAddress the reward address.
    struct ValidatorData {
        address validatorShare;
        address rewardAddress;
    }
    function getValidatorsRequestWithdraw(uint256 _withdrawAmount)
    external
    view
    returns (
        ValidatorData[] memory validators,
        uint256 totalDelegated,
        uint256 bigNodeOperatorLength,
        uint256[] memory bigNodeOperatorIds,
        uint256 smallNodeOperatorLength,
        uint256[] memory smallNodeOperatorIds,
        uint256[] memory operatorAmountCanBeRequested,
        uint256 totalValidatorToWithdrawFrom
    );
}


contract LidostMaticTool is IStMaticTool{

    constructor(){}
    IPoLidoNFT constant PLO = IPoLidoNFT(0x60a91E2B7A1568f0848f3D43353C453730082E46);
    IstMatic constant stMatic = IstMatic(0x9ee91F9f426fA633d227f7a9b000E28b9dfd8599);
    IstakeManger constant stakeManger = IstakeManger(0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D908);

    struct nftInfo{
        uint256 tokenId;
        uint256 amount;
        bool canClaim;
    }

    function getWithdrawLimit(uint256 _amount) external view returns (uint256 liquidity, bool canWithdraw){
        (uint256 totalAmount2WithdrawInMatic, ,) = stMatic.convertStMaticToMatic(_amount);
        require(totalAmount2WithdrawInMatic > 0, "Withdraw ZERO Matic");
        address nodeOperatorRegistry = stMatic.nodeOperatorRegistry();
        INodeOperatorRegistry nodeRegistry = INodeOperatorRegistry(nodeOperatorRegistry);
        (, uint256 totalDelegated, ,,,,,) = nodeRegistry.getValidatorsRequestWithdraw(_amount);
        uint256 totalBuffered = stMatic.totalBuffered();
        uint256 reservedFunds = stMatic.reservedFunds();
        uint256 localActiveBalance = totalBuffered > reservedFunds ? totalBuffered - reservedFunds : 0;
        liquidity = totalDelegated + localActiveBalance;
        canWithdraw = liquidity >= totalAmount2WithdrawInMatic ;
    }

    function getUserInfo(address user) external view returns(nftInfo[] memory userInfo) {
        uint256[] memory userNFT = PLO.getOwnedTokens(user);
        uint256 length = userNFT.length;
        RequestWithdraw memory request;
        RequestWithdraw[] memory requests;

        uint256 currentEpoch;
        uint256 requestEpoch;
        userInfo = new nftInfo[](length);
        for(uint256 i = 0; i < length;) {
            userInfo[i].tokenId = userNFT[i];
            userInfo[i].amount = stMatic.getMaticFromTokenId(userNFT[i]);

            request = stMatic.token2WithdrawRequest(userNFT[i]);
            if(request.requestEpoch != 0) {
                requestEpoch = request.requestEpoch;
            } else {
                requests = stMatic.getToken2WithdrawRequests(userNFT[i]);
                requestEpoch = requests[0].requestEpoch;
            }
            currentEpoch = stakeManger.currentEpoch();

            if(currentEpoch >= requestEpoch) {
                userInfo[i].canClaim = true;
            } else {
                userInfo[i].canClaim = false;
            }
            unchecked {++i;}
        }
    }
}