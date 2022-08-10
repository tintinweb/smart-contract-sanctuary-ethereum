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
        uint256 votes;
    }

    struct Category {
        uint256 id;
        bool exists;
        string description;
        Proposal[] proposals;
        Proposal[] proposalsWin;
        Voter[] voters;
        address[] validVoters;
        uint256 countProporsalsWinners;
        uint256 countProporsals;
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
    Voter[] public voters;
    uint256 public idProporsals;
    uint256 public idCategories;

    uint256 public idVoter;
    uint256 public countProporsals;
    uint256 public countCategories;

    enum level {
        NELSEN,
        NINJA,
        PAISANO
    }

    constructor() {
        owner = msg.sender;
        //daoContract = IdaoContract(0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656);
        validTokens = [
            101832018425899375535984929954058092958993373949978081184254655164517898518529
        ];
        idProporsals = 1;
        idVoter = 1;
        idCategories = 1;
        emit voter(idVoter, msg.sender);
        emit account(msg.sender, level.NELSEN);

        countCategories = 0;
    }

    event proposalCreated(
        uint256 id,
        string description,
        uint256 votes,
        address proposer
    );

    event proposalWin(
        uint256 id,
        string description,
        uint256 votes,
        uint256 idCategory
    );

    event newVote(address voter, uint256 proposal);

    event proposalCount(uint256 id, bool passed);

    event voter(uint256 id, address voter);

    event permission(uint256 idCategory, string categoryDesc, address voter);

    event deletePermission(
        uint256 idCategory,
        string categoryDesc,
        address voter
    );

    event account(address voter, level nivel);

    event removeAccount(address voter, uint256 idCategory);

    event deleteAccount(address voter);

    /*
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

    function checkCategoryEligibility(address _proposalist, uint256 token)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                token = validTokens[i];
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(address _voter) private view returns (bool) {
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i].voter == _voter) {
                return false;
            }
        }
        return true;
    }

    function checkProposalExists(uint256 idProposal, uint256 idCategory)
        private
        view
        returns (bool)
    {
        for (uint256 a = 0; a < categories.length; a++) {
            if (categories[a].id == idCategory) {
                for (uint256 i = 0; i < categories[a].proposals.length; i++) {
                    if (categories[a].proposals[i].id == idProposal) {
                        return true;
                    }
                }
            }
        }
        return false;
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

    function closeVotation(uint256 idCategory) public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios NINJA o NELSEN pueden cerrar la votacion"
        );
        require(checkCategoryExists(idCategory), "No existe la categoria");
        require(
            categories[idCategory].proposals.length > 0,
            "No hay propuestas creadas"
        );

        uint256 votes = 0;
        for (uint256 i = 0; i < categories[idCategory].proposals.length; i++) {
            if (categories[idCategory].proposals[i].votes > votes) {
                votes = categories[idCategory].proposals[i].votes;
            }
        }
        for (uint256 i = 0; i < categories[idCategory].proposals.length; i++) {
            if (categories[idCategory].proposals[i].votes == votes) {
                categories[idCategory].proposalsWin.push(
                    categories[idCategory].proposals[i]
                );
                emit proposalWin(
                    categories[idCategory].proposals[i].id,
                    categories[idCategory].proposals[i].description,
                    categories[idCategory].proposals[i].votes,
                    idCategory
                );
            }
        }

        delete categories[idCategory].voters;
        delete categories[idCategory].proposals;
        categories[idCategory].countProporsals = categories[idCategory]
            .proposals
            .length;
        categories[idCategory].countProporsalsWinners = categories[idCategory]
            .proposalsWin
            .length;
    }

     function deleteProposal(uint256 idProposal, uint256 idCategory) public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden eliminar una propuesta"
        );
        require(
            checkProposalExists(idProposal, idCategory),
            "Esta propuesta o categoria no existe"
        );

        for (uint256 i = 0; i < categories[idCategory].proposals.length; i++) {
            if (categories[idCategory].proposals[i].id == idProposal) {
                categories[idCategory].proposals[i] = categories[idCategory]
                    .proposals[categories[idCategory].proposals.length - 1];
                categories[idCategory].proposals.pop();
                break;
            }
        }

        for (uint256 i = 0; i < categories[idCategory].voters.length; i++) {
            if (categories[idCategory].voters[i].idProposal == idProposal) {
                categories[idCategory].voters[i] = categories[idCategory]
                    .voters[categories[idCategory].voters.length - 1];
                categories[idCategory].voters.pop();
            }
        }

        categories[idCategory].countProporsals = categories[idCategory]
            .proposals
            .length;
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

    function addValidVoter(address newVoter, uint256 idCategory) public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden agregar votantes"
        );
        require(checkCategoryExists(idCategory), "No existe la categoria");

        if (!checkIfValidVoter(idCategory, msg.sender)) {
            if (newVoter != owner && !checkProposalEligibility(newVoter)) {
                categories[idCategory].validVoters.push(newVoter);
                categories[idCategory].idVoter++;
                emit voter(idVoter, newVoter);
                emit account(newVoter, level.PAISANO);
                emit permission(
                    idCategory,
                    categories[idCategory].description,
                    newVoter
                );
            }
        }
    }

    function removeValidVoter(address oldVoter, uint256 idCategory) public {
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios de nivel NELSEN y NINJA pueden eliminar votantes"
        );
        require(checkCategoryExists(idCategory), "No existe la categoria");

        if (checkIfValidVoter(idCategory, msg.sender)) {
            if (oldVoter != owner && !checkProposalEligibility(oldVoter)) {
                for (
                    uint256 i = 0;
                    i < categories[idCategory].validVoters.length;
                    i++
                ) {
                    if (categories[idCategory].validVoters[i] == msg.sender) {
                        categories[idCategory].validVoters[i] = categories[
                            idCategory
                        ].validVoters[
                                categories[idCategory].validVoters.length - 1
                            ];
                        categories[idCategory].validVoters.pop();
                        break;
                    }
                }
                categories[idCategory].idVoter--;
                emit deletePermission(
                    idCategory,
                    categories[idCategory].description,
                    oldVoter
                );
            }
        }
    }

    function checkIfNoVote(uint256 idCategory, address voterAddress)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < categories[idCategory].voters.length; i++) {
            if (categories[idCategory].voters[i].voter == voterAddress) {
                return false;
            }
        }
        return true;
    }

    function checkIfValidVoter(uint256 idCategory, address voterAddress)
        private
        view
        returns (bool)
    {
        for (
            uint256 i = 0;
            i < categories[idCategory].validVoters.length;
            i++
        ) {
            if (categories[idCategory].validVoters[i] == voterAddress) {
                return true;
            }
        }
        return false;
    }

    function voteOnProposal(uint256 idCategory, uint256 idProposal) public {
        require(
            checkProposalExists(idProposal, idCategory),
            "Esta propuesta o categoria no existe"
        );
        bool admin = checkProposalEligibility(msg.sender);
        if (admin == false) {
            require(
                checkIfValidVoter(idCategory, msg.sender),
                "No tienes permiso para votar"
            );
        }
        require(
            checkIfNoVote(idCategory, msg.sender),
            "Ya votaste en esta categoria"
        );

        categories[idCategory].proposals[idProposal].votes++;
        Voter memory newVoter;
        newVoter.idProposal = idProposal;
        newVoter.idCategory = idCategory;
        newVoter.voter = msg.sender;
        categories[idCategory].voters.push(newVoter);
    }
*/

    function createCategory(string calldata _description) public {
        uint256 token = 0;
        /*require(
            checkCategoryEligibility(msg.sender, token),
            "Solo usuarios NINJA o NELSEN pueden crear una propuesta"
        );*/
        Category storage newCategory = categories.push();
        newCategory.id = idCategories;
        newCategory.exists = true;
        newCategory.description = _description;
        newCategory.countProporsalsWinners = 0;
        newCategory.countProporsals = 0;
        countCategories = categories.length;

        idCategories++;
    }

    function createProposal(uint256 idCategory, string calldata description)
        public
    {
        /*require(checkCategoryExists(idCategory), "Esta categoria no existe");
        bool admin = checkProposalEligibility(msg.sender);
        if (admin == false) {
            require(
                categories[idCategory].validVoters[msg.sender] == msg.sender,
                "No tienes permiso para crear una propuesta en esta categoria"
            );
        }*/

        categories[idCategory].countProporsals++;
        Proposal storage newProposal = categories[idCategory].proposals.push();
        newProposal.id = categories[idCategory].countProporsals++;
        newProposal.description = description;
        newProposal.votes = 0;
        newProposal.exists = true;
    }

    function getFirstProposal() public pure returns (uint256 f) {
        return 1;
    }
}