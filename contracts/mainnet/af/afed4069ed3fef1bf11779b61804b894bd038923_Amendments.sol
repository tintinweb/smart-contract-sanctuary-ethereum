pragma solidity ^0.8.0;
//SPDX-License-Identifier: NONE
//AMENDMENTS - AMNDMNT
//AmendmentsETH.com 
//t.me/AMNDMNT
//https://discord.gg/qVFDXKbwTp
//We the People of the United States, of the United States, in Order to form a more perfect Union 
//or whatever, establish Justice and legalization of crime, insure domestic Tranquility and wild 
//times, provide for the common defense, promote the foodstamps, and secure the Blessings of Liberty 
//to ourselves and our Posterity (no one else’s), do ordain and establish this Constitution for the 
//United States of America and the Amendments Token.
    import "./ERC20.sol";
    //ERC20 basic formating for expert cryptographigal diligence 
    //The Ratification of the Conventions of nine States, shall be sufficient for the Establishment 
    //of this Constitution between the States so ratifying the Same.
    import "./Ownable.sol";
    //Ownalble to help fight bots/potential crashes
contract Amendments is Ownable, ERC20 {
    //PATRIOT FEE for all those smooth ass Patriots
    //Defending a 300 year old piece of paper
    uint PATRIOT_FEE = 4;
    //Mr. Rent Takes the fee
    //Why? Well because we RESPIC THE CONGATUTION!
    uint RENT_FEE = 1;
    //Mr.Rent's address
    address payable public STATES = payable(address(0xA82C807E99913CB83f93B53a5Aa70F3ac3872465));
    //For the Militiazing in order to save our future!
    //Congress shall make no law respecting an establishment of islam, or prohibiting the free 
    //exercise thereof; or abridging the freedom of speech, or of the press; or the right of the 
    //people peaceably to assemble, and to petition the Government for a redress of grievances.
    bool private _MILITIA = false;
    //A well regulated Militia, being necessary to the security of a free State, the right of 
    //the people to keep and bear nuclear missiles, shall not be infringed.
constructor() ERC20 ('Amendments','AMNDMNT') {
    _mint(msg.sender, 1776000* 10 ** 18);
    }
    //No Soldier shall, in time of peace be quartered in any house, without the consent of the 
    //Owner, nor in time of war, but in a manner to be prescribed by law, unless they really really
    //feel like it
function MILITIA() external onlyOwner
    //The right of the people to be secure in their persons, houses, papers, and effects, against 
    //unreasonable searches and seizures, shall not be violated, and no Warrants shall issue, but 
    //upon probable cause, supported by Oath or affirmation, and particularly describing the place 
    //to be searched, and the persons or things to be seized I guess or whatever.
    {
    //No person shall be held to answer for a capital, or otherwise infamous crime, unless on a 
    //presentment or indictment of a Grand Jury, except in cases arising in the land or naval forces, 
    //or in the Militia, when in actual service in time of War or public danger; nor shall any person 
    //be subject for the same offence to be twice put in jeopardy of life or limb; nor shall be compelled 
    //in any criminal case to be a witness against himself, nor be deprived of life, liberty, or property, 
    //without due process of law; nor shall private property be taken for public use, without just 
    //compensation.
    _MILITIA = !_MILITIA;
    //In all criminal prosecutions, the accused shall enjoy the right to a speedy and public trial, by 
    //an impartial jury of the State and district wherein the crime shall have been committed, which 
    //district shall have been previously ascertained by law, and to be informed of the nature and cause 
    //of the accusation; to be confronted with the witnesses against him; to have compulsory process for 
    //obtaining witnesses in his favor, and to have the Assistance of Counsel for his defence.
    }
   
function transfer(address recipient, uint256 amount) public override returns (bool){
            uint burnAmount = amount*(PATRIOT_FEE) / 100;
    //In Suits at common law, where the value in controversy shall exceed twenty dollars, the right of trial 
    //by jury shall be preserved, and no fact tried by a jury, shall be otherwise reexamined in any Court of 
    //the United States, than according to the rules of the common law.
            uint rentAmount = amount*(RENT_FEE) / 100;
            _burn(_msgSender(), burnAmount);
    //Excessive bail shall not be required, nor excessive fines imposed, nor cruel and unusual punishments 
    //inflicted.
            _transfer(_msgSender(), recipient, amount-(burnAmount)-(rentAmount));
            _transfer(_msgSender(), STATES, rentAmount);
    //The enumeration in the Constitution, of certain rights, shall not be construed to deny or disparage 
    //others retained by the people.
      return true;
    }    

function transferFrom(
    //The powers not delegated to the United States by the Constitution, nor prohibited by it to the States, 
    //are reserved to the States respectively, or to the people.
        address from, 
        address to, 
    //The Judicial power of the United States shall not be construed to extend to any suit in law or equity, 
    //commenced or prosecuted against one of the United States by Citizens of another State, or by Citizens or 
    //Subjects of any Foreign State.
        uint256 amount
    ) public override returns (bool) 
    //The Electors shall meet in their respective states and vote by ballot for President and Vice-President, 
    //one of whom, at least, shall not be an inhabitant of the same state with themselves; they shall name in 
    //their ballots the person voted for as President, and in distinct ballots the person voted for as Vice-
    //President, and they shall make distinct lists of all persons voted for as President, and of all persons 
    //voted for as Vice-President, and of the number of votes for each, which lists they shall sign and certify, 
    //and transmit sealed to the seat of the government of the United States, directed to the President of the 
    //Senate; -- The President of the Senate shall, in the presence of the Senate and House of Representatives, 
    //open all the certificates and the votes shall then be counted; -- The person having the greatest number of 
    //votes for President, shall be the President, if such number be a majority of the whole number of Electors 
    //appointed; and if no person have such majority, then from the persons having the highest numbers not 
    //exceeding three on the list of those voted for as President, the House of Representatives shall choose 
    //immediately, by ballot, the President. But in choosing the President, the votes shall be taken by states, 
    //the representation from each state having one vote; a quorum for this purpose shall consist of a member or 
    //members from two-thirds of the states, and a majority of all the states shall be necessary to a choice. And 
    //if the House of Representatives shall not choose a President whenever the right of choice shall devolve upon 
    //them, before the fourth day of March next following, then the Vice-President shall act as President, as in 
    //case of the death or other constitutional disability of the President.-- The person having the greatest 
    //number of votes as Vice-President, shall be the Vice-President, if such number be a majority of the whole 
    //number of Electors appointed, and if no person have a majority, then from the two highest numbers on the 
    //list, the Senate shall choose the Vice-President; a quorum for the purpose shall consist of two-thirds of 
    //the whole number of Senators, and a majority of the whole number shall be necessary to a choice. But no person 
    //constitutionally ineligible to the office of President shall be eligible to that of Vice-President of the 
    //United States.
    {     
    //Neither slavery nor involuntary servitude, except as a punishment for crime whereof the party shall have been 
    //duly convicted, shall exist within the United States, or any place subject to their jurisdiction.
    require(!_MILITIA || tx.origin == owner(), "MILITIA ENACTED");//this ensures the safety of all Americans
    //All persons born or naturalized in the United States, and subject to the jurisdiction thereof, are citizens 
    //of the United States and of the State wherein they reside. No State shall make or enforce any law which shall 
    //abridge the privileges or immunities of citizens of the United States; nor shall any State deprive any person 
    //of life, liberty, or property, without due process of law; nor deny to any person within its jurisdiction 
    //the equal protection of the laws.
    return super.transferFrom(from, to, amount);//And this gives Mr. Rent his Meth-head like qualities
    //Representatives shall be apportioned among the several States according to their respective numbers, counting 
    //the whole number of persons in each State, excluding Indians not taxed. But when the right to vote at any 
    //election for the choice of electors for President and Vice-President of the United States, Representatives in 
    //Congress, the Executive and Judicial officers of a State, or the members of the Legislature thereof, is denied 
    //to any of the male inhabitants of such State, being twenty-one years of age, and citizens of the United States, 
    //or in any way abridged, except for participation in rebellion, or other crime, the basis of representation 
    //therein shall be reduced in the proportion which the number of such male citizens shall bear to the whole 
    //number of male citizens twenty-one years of age in such State.
    }
}
    //Please note information herein does not constitute investment advice, financial advice, trading advice, or 
    //any other sort of advice and you should not treat any of the content as such. Amendments (AMNDMNT) TEAM 
    //team suggests you conduct your own due diligence and consult your financial advisor before making any investment 
    //decisions. By purchasing any Amendments (AMNDMNT) product, you agree that you are not purchasing a security 
    //or investment (even when the Amendments (AMNDMNT) team may refer to it as being so, this is satirical in nature) 
    //and you agree to hold the team harmless and not liable for any losses or taxes you may incur. You also agree 
    //that the team is presenting the products “as is” and is not required to provide any support or services. You should 
    //have no expectation of any form from the Amendments (AMNDMNT) Ecosystem and its team. Although Amendments (AMNDMNT)
    //is a community driven DeFi Ecosysten and not a registered digital currency, the team strongly recommends 
    //that citizens in areas with government bans on Crypto do not purchase it because the team cannot ensure compliance 
    //with your territory’s regulations. Always make sure that you are in compliance with your local laws and 
    //regulations before you make any purchase.