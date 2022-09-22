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
        daoContract = IdaoContract(0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656);
        validTokens = [
            101832018425899375535984929954058092958993373949978081184254655164517898518529
        ];
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

    function checkProposalOpen(uint256 indexProposal, uint256 indexCategory)
        private
        view
        returns (bool)
    {
        if (
            categories[indexCategory].proposals[indexProposal].status ==
            proposalStatus.OPEN
        ) {
            return true;
        }

        return false;
    }

    function returnProposalIndex(uint256 idProposal, uint256 indexCategory)
        private
        view
        returns (uint256)
    {
        for (
            uint256 i = 0;
            i < categories[indexCategory].proposals.length;
            i++
        ) {
            if (categories[indexCategory].proposals[i].id == idProposal) {
                return i;
            }
        }

        return 0;
    }

    function returnOptionIndex(
        uint256 indexProposal,
        uint256 indexCategory,
        uint256 idOption
    ) private view returns (uint256) {
        for (
            uint256 i = 0;
            i <
            categories[indexCategory].proposals[indexProposal].options.length;
            i++
        ) {
            if (
                categories[indexCategory]
                    .proposals[indexProposal]
                    .options[i]
                    .id == idOption
            ) {
                return i;
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

    function closeVotation(uint256 idCategory, uint256 idProporsal) public {
        uint256 indexCategory;
        uint256 indexProposal;
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios NINJA o NELSEN pueden cerrar la votacion"
        );
        require(
            checkProposalExists(idProporsal, idCategory),
            "No existe la categoria o propuesta"
        );
        indexCategory = returnIndexCategory(idCategory);
        indexProposal = returnProposalIndex(idProporsal, indexCategory);

        uint256 votes = 0;
        if (
            categories[indexCategory].proposals[indexProposal].typeProposal ==
            proposalType.MULTIPLE_CHOICE
        ) {
            for (
                uint256 i = 0;
                i <
                categories[indexCategory]
                    .proposals[indexProposal]
                    .options
                    .length;
                i++
            ) {
                if (
                    categories[indexCategory]
                        .proposals[indexProposal]
                        .options[i]
                        .countVotes > votes
                ) {
                    votes = categories[indexCategory]
                        .proposals[indexProposal]
                        .options[i]
                        .countVotes;
                }
            }
            for (
                uint256 i = 0;
                i <
                categories[indexCategory]
                    .proposals[indexProposal]
                    .options
                    .length;
                i++
            ) {
                if (
                    categories[indexCategory]
                        .proposals[indexProposal]
                        .options[i]
                        .countVotes == votes
                ) {
                    categories[indexCategory]
                        .proposals[indexProposal]
                        .winnerOptions
                        .push(
                            categories[indexCategory]
                                .proposals[indexProposal]
                                .options[i]
                        );
                }
            }
        }

        categories[indexCategory]
            .proposals[indexProposal]
            .status = proposalStatus.CLOSED;

        categories[indexCategory].proposalsClosed.push(
            categories[indexCategory].proposals[indexProposal]
        );
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

    function addValidVoter(address newVoter, uint256 idCategory) public {
        uint256 indexCategory;
        require(
            checkProposalEligibility(msg.sender),
            "Solo usuarios duenos del NFT pueden agregar votantes"
        );
        require(checkCategoryExists(idCategory), "No existe la categoria");
        indexCategory = returnIndexCategory(idCategory);

        if (!checkIfValidVoter(indexCategory, msg.sender)) {
            if (newVoter != owner && !checkProposalEligibility(newVoter)) {
                categories[indexCategory].validVoters.push(newVoter);
                categories[indexCategory].idVoter++;
                emit voter(idVoter, newVoter);
                emit account(newVoter, level.PAISANO);
                emit permission(
                    idCategory,
                    categories[indexCategory].description,
                    newVoter
                );
            }
        }
    }

    function checkIfNoVote(
        uint256 idCategory,
        uint256 idProporsal,
        address voterAddress
    ) private view returns (bool) {
        for (
            uint256 i = 0;
            i < categories[idCategory].proposals[idProporsal].voters.length;
            i++
        ) {
            if (
                categories[idCategory].proposals[idProporsal].voters[i].voter ==
                voterAddress
            ) {
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

    function checkTypeProposalBoolean(
        uint256 indexCategory,
        uint256 indexProposal
    ) private view returns (bool) {
        if (
            categories[indexCategory].proposals[indexProposal].typeProposal ==
            proposalType.BOOLEAN
        ) {
            return true;
        }
        return false;
    }

    function checkTypeProposalOptions(
        uint256 indexCategory,
        uint256 indexProposal
    ) private view returns (bool) {
        if (
            categories[indexCategory].proposals[indexProposal].typeProposal ==
            proposalType.MULTIPLE_CHOICE
        ) {
            return true;
        }
        return false;
    }

    function voteOnProposalBoolean(
        uint256 idCategory,
        uint256 idProposal,
        bool vote
    ) public {
        uint256 indexCategory;
        uint256 indexProposal;

        require(
            checkProposalExists(idProposal, idCategory),
            "Esta propuesta o categoria no existe"
        );

        indexCategory = returnIndexCategory(idCategory);
        indexProposal = returnProposalIndex(idProposal, indexCategory);
        require(
            checkTypeProposalBoolean(indexCategory, indexProposal),
            "Esta propuesta no es de tipo booleana"
        );
        require(
            checkProposalOpen(indexProposal, indexCategory),
            "Esta propuesta se encuentra cerrada"
        );
        bool admin = checkProposalEligibility(msg.sender);
        if (admin == false) {
            require(
                checkIfValidVoter(indexCategory, msg.sender),
                "No tienes permiso para votar"
            );
        }
        require(
            checkIfNoVote(indexCategory, indexProposal, msg.sender),
            "Ya votaste en esta propuesta"
        );
        if (vote == true) {
            categories[indexCategory].proposals[indexProposal].countPositive++;
            categories[indexCategory].proposals[indexProposal].countVotes++;
            categories[indexCategory].proposals[indexProposal].positive.push(
                vote
            );
        }

        if (vote == false) {
            categories[indexCategory].proposals[indexProposal].countNegative++;
            categories[indexCategory].proposals[indexProposal].countVotes++;
            categories[indexCategory].proposals[indexProposal].negative.push(
                vote
            );
        }

        Voter memory newVoter;
        newVoter.idProposal = idProposal;
        newVoter.idCategory = idCategory;
        newVoter.voter = msg.sender;
        categories[indexCategory].proposals[indexProposal].voters.push(
            newVoter
        );
    }

    function voteOnProposalOptions(
        uint256 idCategory,
        uint256 idProposal,
        uint256 idOptions
    ) public {
        uint256 indexCategory;
        uint256 indexProposal;

        require(
            checkProposalExists(idProposal, idCategory),
            "Esta propuesta o categoria no existe"
        );

        indexCategory = returnIndexCategory(idCategory);
        indexProposal = returnProposalIndex(idProposal, indexCategory);
        require(
            checkTypeProposalOptions(indexCategory, indexProposal),
            "Esta propuesta no es de tipo booleana"
        );
        require(
            checkProposalOpen(indexProposal, indexCategory),
            "Esta propuesta se encuentra cerrada"
        );
        bool admin = checkProposalEligibility(msg.sender);
        if (admin == false) {
            require(
                checkIfValidVoter(indexCategory, msg.sender),
                "No tienes permiso para votar"
            );
        }
        require(
            checkIfNoVote(indexCategory, indexProposal, msg.sender),
            "Ya votaste en esta propuesta"
        );
        uint256 indexOption = returnOptionIndex(
            indexProposal,
            indexCategory,
            idOptions
        );
        categories[indexCategory]
            .proposals[indexProposal]
            .options[indexOption]
            .countVotes++;

        Voter memory newVoter;
        newVoter.idProposal = idProposal;
        newVoter.idCategory = idCategory;
        newVoter.voter = msg.sender;
        categories[indexCategory].proposals[indexProposal].voters.push(
            newVoter
        );
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

    event Received(uint256 value);

    function deposit() public payable {
        emit Received(msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    fallback() external payable {
        emit Received(msg.value);
    }

    receive() external payable {
        emit Received(msg.value);
    }

    function createProposalBoolean(
        uint256 idCategory,
        string calldata description
    ) public {
        uint256 index;
        require(checkCategoryExists(idCategory), "Esta categoria no existe");
        index = returnIndexCategory(idCategory);
        bool admin = checkProposalEligibility(msg.sender);
        if (admin == false) {
            require(
                checkIfValidVoter(index, msg.sender),
                "No tienes permiso para crear una propuesta en esta categoria"
            );
        }

        categories[index].countProporsals++;
        categories[index].idProporsal++;
        Proposal storage newProposal = categories[index].proposals.push();
        newProposal.id = categories[index].idProporsal;
        newProposal.description = description;
        newProposal.countNegative = 0;
        newProposal.countPositive = 0;
        newProposal.countVotes = 0;
        newProposal.typeProposal = proposalType.BOOLEAN;
        newProposal.status = proposalStatus.OPEN;
        newProposal.exists = true;
    }

    function createProposalOptions(
        uint256 idCategory,
        string calldata proposal_description,
        string[] calldata descriptions
    ) public {
        uint256 index;
        require(checkCategoryExists(idCategory), "Esta categoria no existe");
        index = returnIndexCategory(idCategory);

        bool admin = checkProposalEligibility(msg.sender);

        if (admin == false) {
            require(
                checkIfValidVoter(index, msg.sender),
                "No tienes permiso para crear una propuesta en esta categoria"
            );
        }

        categories[index].countProporsals++;
        categories[index].idProporsal++;
        Proposal storage newProposal = categories[index].proposals.push();
        for (uint256 i = 0; i < descriptions.length; i++) {
            Options storage newOptions = newProposal.options.push();
            newOptions.id = i + 1;
            newOptions.countVotes = 0;
            newOptions.description = descriptions[i];
        }
        newProposal.id = categories[index].idProporsal;
        newProposal.countNegative = 0;
        newProposal.countPositive = 0;
        newProposal.countVotes = 0;
        newProposal.description = proposal_description;
        newProposal.typeProposal = proposalType.MULTIPLE_CHOICE;
        newProposal.status = proposalStatus.OPEN;
        newProposal.exists = true;
    }

    function getProposalsByCategoryId(uint256 categoryId)
        public
        view
        returns (Proposal[] memory)
    {
        require(checkCategoryExists(categoryId), "Esta categoria no existe");
        uint256 index = returnIndexCategory(categoryId);
        Proposal[] memory view_proposals = new Proposal[](
            categories[index].countProporsals
        );
        for (uint256 i = 0; i < categories[index].proposals.length; i++) {
            Proposal storage proposal = categories[index].proposals[i];
            view_proposals[i] = proposal;
        }
        return view_proposals;
    }

    function getOptionsWinnersByCategoryId(
        uint256 categoryId,
        uint256 proposalId
    ) public view returns (Options[] memory) {
        require(
            checkProposalExists(proposalId, categoryId),
            "Esta categoria o propuesta no existe"
        );
        uint256 indexCategory = returnIndexCategory(categoryId);
        uint256 indexProposal = returnProposalIndex(proposalId, indexCategory);
        Options[] memory view_options_win = new Options[](
            categories[indexCategory]
                .proposals[indexProposal]
                .winnerOptions
                .length
        );
        for (
            uint256 i = 0;
            i <
            categories[indexCategory]
                .proposals[indexProposal]
                .winnerOptions
                .length;
            i++
        ) {
            Options storage option = categories[indexCategory]
                .proposals[indexProposal]
                .winnerOptions[i];
            view_options_win[i] = option;
        }
        return view_options_win;
    }

    function getOptionsByCategoryId(uint256 categoryId, uint256 proposalId)
        public
        view
        returns (Options[] memory)
    {
        require(
            checkProposalExists(proposalId, categoryId),
            "Esta categoria o propuesta no existe"
        );
        uint256 indexCategory = returnIndexCategory(categoryId);
        uint256 indexProposal = returnProposalIndex(proposalId, indexCategory);
        Options[] memory view_options = new Options[](
            categories[indexCategory].proposals[indexProposal].options.length
        );
        for (
            uint256 i = 0;
            i <
            categories[indexCategory].proposals[indexProposal].options.length;
            i++
        ) {
            Options storage option = categories[indexCategory]
                .proposals[indexProposal]
                .options[i];
            view_options[i] = option;
        }
        return view_options;
    }
}