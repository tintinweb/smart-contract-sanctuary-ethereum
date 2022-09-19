/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface Token{
    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns(uint256);

    function getHolderByIndex(uint256 _index) external view returns(address);

    function holdersCount() external view returns(uint256);

    function totalSupply() external view returns(uint256);
}

contract MultiSig {
    address public tokenAddress;
    Token private token;

    mapping(address => bool) public owners;
    uint256 public ownersCount;

    struct Voting{
        uint256 _for;
        uint256 _against;
    }

    struct Transaction{
        uint256 _amount;
        address _to;
        string _status;
    }

    mapping(address => Voting) public candidatesVotesCount;
    mapping(address => bool) public candidatesForOwner;
    mapping(address => mapping(address => bool)) public ownersVotesForCandidate;

    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionIndex;
    mapping(uint256 => Voting) public transactionsVotesCount;
    mapping(address => mapping(uint256 => bool)) public ownersVotesForTransaction;


    constructor (){
        owners[msg.sender] = true;
        ownersCount++;
        tokenAddress = 0x315756BA3241255EAe134d126077E5326E4a95Bd;
        token = Token(tokenAddress);
    }

    modifier onlyOwner(){
        require(owners[msg.sender], "Sender is not the owner");
        _;
    }

    function checkBalance() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    function changeTokenAddress(address _new) external{
        tokenAddress = _new;
        token = Token(tokenAddress);
    }

    function becomeCandidate() external{
        require(!owners[msg.sender], "Sender is already the owner");
        require(!candidatesForOwner[msg.sender], "Sender is already the owner");
        candidatesForOwner[msg.sender] = true;
    }

    function voteForTheCandidate(address _candidate, bool _vote) external onlyOwner{
        require(
            !ownersVotesForCandidate[msg.sender][_candidate], 
            "Owner has already voted for this candidate"
            );
        require(candidatesForOwner[_candidate], "This address is not the candidate");
        
        if(_vote){
            candidatesVotesCount[_candidate]._for++;

            if (candidatesVotesCount[_candidate]._for > ownersCount/2){
                owners[_candidate] = true;
                candidatesForOwner[_candidate] = false;
                delete(candidatesVotesCount[_candidate]);
                ownersCount++;
            }
        }
        else{
            candidatesVotesCount[_candidate]._against++;

            if(candidatesVotesCount[_candidate]._against >= ownersCount/2){
                candidatesForOwner[_candidate] = false;
                delete(candidatesVotesCount[_candidate]);
            }
        }
    }

    function offerTransaction(address _to, uint256 _amount) external onlyOwner{
        require(token.balanceOf(address(this)) >= _amount, "Not enough tokens on wallet");
        transactionIndex++;
        transactions[transactionIndex] = Transaction(_amount, _to, "On voting");
    }

    function voteForTheTransaction(uint256 _transactionID, bool _vote) external onlyOwner{
        require(
            !ownersVotesForTransaction[msg.sender][_transactionID], 
            "Owner has already voted for this transaction"
            );
        require(_transactionID <= transactionIndex, "This transaction doesn't exist yet");
        require(
            keccak256(abi.encodePacked(transactions[_transactionID]._status)) == keccak256(abi.encodePacked("On voting")), 
            "This transaction not on voting"
            );

        if(_vote){
            transactionsVotesCount[_transactionID]._for++;

            if (transactionsVotesCount[_transactionID]._for > ownersCount/2){
                require(
                    token.balanceOf(address(this)) >= transactions[_transactionID]._amount, 
                    "Not enough tokens on wallet"
                    );

                token.transfer(
                    transactions[_transactionID]._to, 
                    transactions[_transactionID]._amount
                    );
                transactions[_transactionID]._status = "Submitted";
            }
        }
        else{
            transactionsVotesCount[_transactionID]._against++;

            if(transactionsVotesCount[_transactionID]._against >= ownersCount/2){
                transactions[_transactionID]._status = "Denied";
            }
        }
    }
}