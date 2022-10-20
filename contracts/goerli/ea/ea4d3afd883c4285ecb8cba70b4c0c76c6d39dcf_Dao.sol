/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
     struct Proposal {
        uint256 id;
        bool exists;
        string description;
        proposalType typeProposal;
        Voter[] voters;
        bool[] positive;
        bool[] negative;
        uint256 countPositive;
        uint256 countNegative;
        uint256 countVotes;
        Options[] options;
        proposalStatus status;
        bool winner;
        Options[] winnerOptions;
    }

    struct Category {
        uint256 id;
        bool exists;
        string description;
        Proposal[] proposals;
        Proposal[] proposalsClosed;
        address[] validVoters;
        uint256 countProporsalsClosed;
        uint256 countProporsals;
        uint256 idProporsal;
        address creator;
        uint256 token;
        uint256 idVoter;
    }

    address public owner;
    uint256[] public validTokens;
    IdaoContract daoContract;
    Category[] public categories;
    struct Voter {
        address voter;
        uint256 idProposal;
        uint256 idCategory;
    }
    struct Options {
        uint256 id;
        string description;
        uint256 countVotes;
    }
    Voter[] public voters;
    uint256 public idCategories;
    uint256 public idVoter;
    uint256 public countCategories;

    enum level {
        NELSEN,
        NINJA,
        PAISANO
    }

    enum proposalType {
        BOOLEAN,
        MULTIPLE_CHOICE
    }

    enum proposalStatus {
        CLOSED,
        OPEN
    }

    constructor() {
        owner = msg.sender;
        daoContract = IdaoContract(0xf4910C763eD4e47A585E2D34baA9A4b611aE448C);
        validTokens = [
            97523909273001091599219093796278486735169410612904444496283823191965313269761
        ];
        idVoter = 1;
        idCategories = 1;
        emit voter(idVoter, msg.sender);
        emit account(msg.sender, level.NELSEN);
        countCategories = 0;
    }

    event voter(uint256 id, address voter);

    event account(address voter, level nivel);

    event removeAccount(address voter, uint256 idCategory);

    function getCategories() public view returns(Category[] memory){
        return categories;
    }

    function checkProposalEligibility(address _proposalist)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function checkCategoryEligibility(address _proposalist)
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return validTokens[i];
            }
        }
        return 0;
    }

    function checkCategoryExists(uint256 idCategory)
        private
        view
        returns (bool)
    {
        for (uint256 a = 0; a < categories.length; a++) {
            if (categories[a].id == idCategory) {
                return true;
            }
        }
        return false;
    }

    function returnIndexCategory(uint256 idCategory)
        private
        view
        returns (uint256)
    {
        for (uint256 a = 0; a < categories.length; a++) {
            if (categories[a].id == idCategory) {
                return a;
            }
        }
        return 0;
    }

    function deleteCategory(uint256 idCategory) public {
        uint256 indexCategory;
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden eliminar una propuesta"
        );
        require(checkCategoryExists(idCategory), "Esta categoria no existe");
        indexCategory = returnIndexCategory(idCategory);
        categories[indexCategory] = categories[categories.length - 1];
        categories.pop();

        countCategories = categories.length;
    }

    function addTokenId(uint256 _tokenId, address token_address) public {
        require(msg.sender == owner, "Solamente NELSEN puede agregar tokens");

        require(
            daoContract.balanceOf(token_address, _tokenId) >= 1,
            "El token no corresponde a la cuenta proporcionada"
        );

        validTokens.push(_tokenId);
        emit account(token_address, level.NINJA);
    }

    function createCategory(string calldata _description) public {
        uint256 token = checkCategoryEligibility(msg.sender);
        require(
            token != 0,
            "Solo usuarios NINJA o NELSEN pueden crear una propuesta"
        );
        Category storage newCategory = categories.push();
        newCategory.id = idCategories;
        newCategory.exists = true;
        newCategory.description = _description;
        newCategory.countProporsals = 0;
        newCategory.token = token;
        newCategory.creator = msg.sender;
        countCategories = categories.length;

        idCategories++;
    }

}