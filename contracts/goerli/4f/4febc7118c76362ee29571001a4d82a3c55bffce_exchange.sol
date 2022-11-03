/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

pragma solidity ^0.8.0;

contract exchange 
{
    struct AccountLeaf
    {
        uint32   accountID;
        address  owner;
        uint     pubKeyX;
        uint     pubKeyY;
        uint32   nonce;
    }

    struct BalanceLeaf
    {
        uint32  tokenID;
        uint248 balance;
    }

    struct MerkleProof
    {
        AccountLeaf accountLeaf;
        BalanceLeaf balanceLeaf;
        uint[48]                 accountMerkleProof;
        uint[48]                 balanceMerkleProof;
    }

    event WithdrawMerkle(
        address owner,
        uint32   accountID,
        uint32 tokenID,
         uint248 balance
    );

    function withdrawFromMerkleTree(
        MerkleProof calldata merkleProof
        )
        external

    {
        address owner = merkleProof.accountLeaf.owner;
        uint32 accountID = merkleProof.accountLeaf.accountID;
        uint32 tokenID = merkleProof.balanceLeaf.tokenID;
        uint248 balance = merkleProof.balanceLeaf.balance;

        emit WithdrawMerkle(owner, accountID, tokenID, balance);
    }


}