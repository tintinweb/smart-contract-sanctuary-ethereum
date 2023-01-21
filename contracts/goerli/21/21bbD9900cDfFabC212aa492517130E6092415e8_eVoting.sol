//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


contract eVoting{
    struct Voter{
        bool registered;//true daca s-a inregistrat
        bool voted;//true daca a votat, sau false in caz contrariu
        bytes32 publicValue;//valoarea cheii publice
        bytes32 ZKP;//ZKP pentru a verifica existenta cheii private
    }

    struct Session{
        uint timeStartRegistry;//setare timp cand va incepe sesiunea de vot
        uint timeStopRegistry;//setare final inregistrare
        uint timeStartVote;//setare timp cand incepe sesiunea de votare
        uint timeStopVote;//setare timp cand este gata sesiunea de votare
        uint timetoShowResult;//setare timp pentru afisare rezultate finale
        bytes32 generator;//generator pentru criptare
        bytes32 module;//modulul in care se fac calculelele
        bytes32[]encryptedVotes;//voturile criptate
        bytes32 message;//setare mesaj sesiune de vot
        bytes32 result;//rezultat criptat
    }
    
    address public adminAddress;
    mapping(address => Voter)public voters;
    address[] eligibleVoters;
    Session public session;

    constructor(uint timeStartRegistry,uint timeStopRegistry,uint timeStartVote,uint timeStopVote,uint timeToShowResult,bytes32 generator,bytes32 module,bytes32 message){
        adminAddress=msg.sender;

        session.timeStartRegistry=timeStartRegistry;
        session.timeStopRegistry=timeStopRegistry;
        session.timeStartVote=timeStartVote;
        session.timeStopVote=timeStopVote;
        session.timetoShowResult=timeToShowResult;
        session.generator=generator;
        session.module=module;
        session.message=message;
        
    }

    function updateTimesForSession(uint timeStartRegistry,uint timeStopRegistry,uint timeStartVote,uint timeStopVote,uint timeToShowResult)public{
        require(adminAddress==msg.sender,"Numai administratorul poate reseta timpii!");

        session.timeStartRegistry=timeStartRegistry;
        session.timeStopRegistry=timeStopRegistry;
        session.timeStartVote=timeStartVote;
        session.timeStopVote=timeStopVote;
        session.timetoShowResult=timeToShowResult;
    }

    function updateMessageSession(bytes32 message)public{
        require(msg.sender==adminAddress,"Numai administratorul poate schimba mesajul!");

        session.message=message;
    }

    function updateGeneratorAndModule(bytes32 generator,bytes32 module)public{
        require(msg.sender==adminAddress,"Numai administratorul poate schimba generatorul si modulul!");
        
        session.generator=generator;
        session.module=module;

    }

    function clearData()public{
        require(msg.sender==adminAddress,"Numai administratorul poate sterge datele!");

        delete session;
        delete eligibleVoters;

    }

    function setEligibleVoters(address[] memory votersAddresses)public{
        require(msg.sender==adminAddress,"Numai administratorul poate stabili cine este eligibil pentru vot!");

        for(uint i=0;i<votersAddresses.length;++i){
            eligibleVoters.push(votersAddresses[i]);
            voters[votersAddresses[i]].registered=false;
        }
    }

    function takeGeneratorAndModule()public view returns(bytes32 generator,bytes32 module){
        generator=session.generator;
        module=session.module;
    }


    function registrationToSession(bytes32 publicValue)public{
        
        require(session.timeStartRegistry< block.timestamp,"Inca nu va puteti inregistra!");
        require(session.timeStopRegistry> block.timestamp,"Nu va mai puteti inregistra!");

        bool eligible=false;

        for(uint i=0;i<eligibleVoters.length;++i){
            if(eligibleVoters[i]==msg.sender){
                eligible=true;
            }
        }

        require(eligible==true,"Nu sunteti eligibil pentru a vota!");

        voters[msg.sender].registered=true;
        voters[msg.sender].voted=false;
        voters[msg.sender].publicValue=publicValue;
    }

    function takePublicValues()public view returns(bytes32[] memory publicValues){

        publicValues = new bytes32[](eligibleVoters.length);

        for(uint i=0;i<eligibleVoters.length;++i){
            publicValues[i]=voters[eligibleVoters[i]].publicValue;
        }

    }

    function vote(bytes32 encryptedVote)public{
        require(session.timeStartVote<block.timestamp,"Inca nu puteti vota!");
        require(session.timeStopVote>block.timestamp,"Nu mai puteti vota!");

        bool eligible=false;

        for(uint i=0;i<eligibleVoters.length;++i){
            if(eligibleVoters[i]==msg.sender){
                eligible=true;
            }
        }

        require(eligible==true,"Nu sunteti eligibil pentru a vota!");
        require(voters[msg.sender].voted==false,"Ati votat deja!"); 

        session.encryptedVotes.push(encryptedVote);

        voters[msg.sender].voted=true;
    }

    function takeVotes()public view returns (bytes32[] memory votes_){
        require(session.timeStopVote<block.timestamp,"Sesiunea de votare nu s-a terminat!");

        votes_=session.encryptedVotes;
    }

    function saveResult(bytes32 result)public{
        require(msg.sender==adminAddress,'Doar administratorul poate anunta rezultatul final!');
        require(session.timeStopVote<block.timestamp,'Inca nu s-a terminat sesiunea de votare!');
        require(session.timetoShowResult>block.timestamp,'Nu se mai poate salva rezultatul!');

        session.result=result;
    }

    function takeResult()public view returns(bytes32 generator,bytes32 result,bytes32 module){
        
        generator=session.generator;
        result=session.result;
        module=session.module;
    }

}