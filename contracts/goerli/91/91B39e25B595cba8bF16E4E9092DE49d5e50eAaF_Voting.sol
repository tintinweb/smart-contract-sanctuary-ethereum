// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    // Création de la structure de la whitelist.
    struct Whitelist {
        address user;
        bool isWhitelisted;
        bool hasProposed;
    }

    // Création de la structure des inscrits (voteurs).
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    // Création de la structure des propositions.
    struct Proposal {
        string description;
        uint voteCount;
    }

    // Différents mappings respectivement déclarée aux structs.
    mapping(address => Whitelist) whitelisteds;
    mapping(address => Voter) voters;
    mapping(address => Proposal) proposals;

    // Mapping d'un nombre vers les propositions pour le voteCount.
    mapping(uint => Proposal) proposalsUint;

    // Tableau pour permettre de récupérer les fonctions dans un tableau.
    address[] whitelistedsArray;
    string[] proposalsStringArray;
    Proposal[] proposalsArray;

    // Différents états du smart-contracts
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public defaultStatus;

    // Différents évènements
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    // Permet à l'Owner d'ajouter à la main les whitelistés.
    function a_addWhitelist(address _user) public onlyOwner {
        whitelisteds[_user].user = _user; // Ajout d'une adresse à la whitelist.
        whitelisteds[_user].isWhitelisted = true; // Notification de l'inscription à la whitelist.
        whitelistedsArray.push(_user); 
    }

    // Permet de savoir qui est whitelisté.
    function b_getWhitelist() public view returns(address[] memory){

        address[] memory _adresses = new address[](whitelistedsArray.length);

        for (uint i = 0; i < whitelistedsArray.length; i++) {
            _adresses[i] = whitelistedsArray[i];
        }
        return whitelistedsArray;
    }


    // Fonctions qui permettent de commencer et stopper les 2 sessions.
    bool startAndStopProposal = false;
    bool startAndStopVote = false;

    function c_startProposal() public onlyOwner {
        startAndStopProposal = true;
        defaultStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    function e_stopProposal() public onlyOwner {
        startAndStopProposal = false;
        defaultStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    function h_startVote() public onlyOwner {
        startAndStopVote = true;
        defaultStatus = WorkflowStatus.VotingSessionStarted;
    }

    function j_stopVote() public onlyOwner {
        defaultStatus = WorkflowStatus.VotingSessionEnded;
        startAndStopVote = false;
    }


    /*
    function isWhitelist(address _user) public view returns(bool){
        if(whitelisteds[_user].hasProposed == true){
            return true;
        }
        return false;
    } */

    // Début de la session de propositions pour les whitelistés.
    function d_propositionSession(string memory _description) public {
        require(startAndStopProposal == true, unicode"La session de proposition n'est pas active."); // Condition qui vérifie si la session de proposition est active.
        require(whitelisteds[msg.sender].isWhitelisted == true && whitelisteds[msg.sender].hasProposed == false, unicode"Vous n'êtes pas autorisé à créer une proposition."); // Condition qui vérifie si msg.sender est whitelisté et n'a jamais proposé de proposition.
        
        whitelisteds[msg.sender].hasProposed = true; // msg.sender a déjà fait une proposition.
        proposalsStringArray.push(_description); // Récupérer la description de la proposition dans un tableau pour getProposals().
        uint _voteCount; 
        Proposal memory thisProposal = Proposal(_description, _voteCount);
        proposalsArray.push(thisProposal); // Ajouter la proposition au tableau de proposition pour pouvoir le parcourir ensuite
        emit ProposalRegistered(_voteCount);
    }

    // Permet de récupérer les propositions.
    function f_getProposals() public view returns(string[] memory){

        // Créer un tableau pour stocker les propositions .
        string[] memory _proposals = new string[](proposalsStringArray.length);

        // Remplir le tableau avec les propositions.
        for (uint i = 0; i < proposalsStringArray.length; i++) {
            _proposals[i] = proposalsStringArray[i];
        }
        return proposalsStringArray;
    }


    //Permet de récupérer la proposition d'une adresse
    /*function getPropositionOfAddress(address _user) public view returns(string memory){
        if(voters[msg.sender].isRegistered != true){ 
            if(whitelisteds[msg.sender].isWhitelisted != true){ // Vérifie si l'utilisateur est inscrit en tant que voter OU est whitelisté
                revert NotRegisteredAtVoter();
            }
        }
        return proposals[_user].description;
    }*/

    // Fonction qui permet aux utilisateurs de s'inscrire en tant que voters.
    function g_votersInscription(address _user) public {
        require(msg.sender == _user || msg.sender == owner(), unicode"Vous n'êtes pas autorisé.");
        voters[_user].isRegistered = true;
        emit VoterRegistered(_user);

        defaultStatus = WorkflowStatus.RegisteringVoters;

    } 
    
    // Permet de démarrer la session de vote en rentrant l'adresse qui nous intéresse.
    function i_voteSession(uint _proposalId) public {
        require(startAndStopProposal == false, unicode"La session de proposition n'est pas terminée."); // Condition qui vérifie si les propositions sont finis.
        require(startAndStopVote == true, unicode"La session de vote n'est pas active."); // Condition qui vérfiie si la session a bien commencé.
        require(voters[msg.sender].isRegistered == true || whitelisteds[msg.sender].isWhitelisted == true, unicode"Vous n'êtes pas autorisé à voté."); // Conditions qui vérifie si le voteur est inscrit ou whitelisté.
        require(voters[msg.sender].hasVoted == false, unicode"Vous avez déjà voté !"); // Condition qui vérifie si le voteur a déjà voté.
        voters[msg.sender].hasVoted = true; // Le voteur a déjà voté.
        proposalsUint[_proposalId].voteCount++; // Incrémentation du nombre de vote par proposition.
        proposalsArray[_proposalId].voteCount++; // Incrémentation du voteCount pour la fonction getWinner.
        voters[msg.sender].votedProposalId = _proposalId; // Actualiser la proposition du voteur.
        emit Voted(msg.sender, _proposalId);
    }

    // Récupérer le nombre de vote que possède une proposition
    function k_getCount(uint _proposalId) public returns(uint){
        defaultStatus = WorkflowStatus.VotesTallied;
        return proposalsUint[_proposalId].voteCount;
    }

    // Fonction qui retournera la proposition gagnante
    function m_getWinner() public view returns(string memory){
            require(startAndStopVote == false, unicode"La session de vote n'est pas terminée."); // Condition qui vérifie si les votes sont finis.

            Proposal memory winProposal = proposalsArray[0]; // Création de la proposition gagnante et définie comme la première.

            // Boucle qui parcours le tableau de proposition et de vérifier si la proposition gagnante (ci-dessus) a plus de vote que la proposition qui suit dans le tableau.
            for(uint i = 1; i < proposalsArray.length; i++){
                if(proposalsArray[i].voteCount > winProposal.voteCount){ // Si la condition d'après (en i) est plus grande que la proposition gagnante définie ci-dessus.
                    winProposal = proposalsArray[i]; // Alors du change la proposition gagnante à la nouvelle proposition (en i) qui possède le plus de votes.
                }
            }
            return winProposal.description; // Retourne moi uniquement la description de la proposition gagnante
            // Si on veut récupérer le voteCount de la proposition gagnante, on aurait retiré le .descriptin et décris que la valeur
            // que l'on veut retourner dans la fonction est "Proposal memory").
    }
}

// J'ai nommé les différentes fonctions avec des lettres devant pour avoir un ordre des fonctions a exécuter