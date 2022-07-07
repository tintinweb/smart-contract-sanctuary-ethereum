// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Time and space and the secret code
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    In the early stages of reaching the Yellow Pole, the pool grows tens of times larger, as big as a basketball.                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Real gas is still rare in the pool, a mass the size of an egg and less than a tenth of its capacity.                                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Only when the real qi in the qi pool is repaired, can we impact the next realm, the middle stage of the Yellow Pole.                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen sat cross-legged, close his eyes, eyebrow heart of the divine martial mark open, began to practice "nine days of emperor Ming classics" the first layer "too huang Huang day".                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    True qi flows out from the qi pool and flows through the whole body along the meridians opened up.                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    With the movement of the real qi in his body, Zhang ruochen's body was like a whirlpool and began to slowly absorb the reiki between heaven and earth.                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Heaven and earth aura, flow into the heart of the divine mark.                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Shenwu mark will be converted into the world reiki, stored in the qi pool. The true qi flows out of the chi pool, along the meridians, and moves the whole body.                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    When the real qi moves around the body, it is a week day.                                                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    After nine days of operation, zhang opened his eyes again and found that the amount of real qi in his body had doubled, reaching one-tenth of the pool's capacity.                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    If other fighters knew that they could double the amount of real qi in their bodies in such a short time, they would be ecstatic.                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    However, Zhang Ruochen was not satisfied, "After practicing for nine weeks, I actually increased my real qi, too slow! If only I could get one! My training speed can be doubled!"                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    We should know that Zhang Ruochen's practice is the "Nine Days of Emperor Ming Sutra", the absorption of true qi speed than those who practice low skills faster.                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    The current speed of training, naturally let him very dissatisfied.                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Having a psionic crystal would speed things up a lot.                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    A psionic crystal, a collection of reiki into crystals.                                                                                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    It is possible to excavate "natural psychics" from underground veins, or to kill wild beasts and extract "acquired psychics" from their bodies.                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    One psicrystal was usually worth as much as a thousand silver coins, and only a great nobleman, or a genius raised by a great family, had access to it.                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    One thousand silver coins, to the present Zhang Ruochen and Lin Fei, is absolutely a huge number, it is impossible to afford.                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "Psionic crystals!                                                                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen's heart move, immediately that one has been wearing in the body of white jujube shaped crystal stone out, in the palm of the hand.                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Could this be a psionic crystal?                                                                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    The real qi was moving inside him, and the mark of the divine force between his eyebrows appeared in a round halo the size of a coin.                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    A white true qi, shot from the brow, hit the white SPAR above.                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "Wow!"                                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    On the surface of the white SPAR, four ancient characters emerge.                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    That's weird!                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen has never seen such characters, but one eye will recognize the four characters - "time and space stone".                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    To know, in the last life time, Zhang Ruochen also put the real gas into the white crystal stone, but, but never crystal stone surface of the text inspired.                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "In my last life, my suo was hundreds of times more powerful than it is now, and I did not make words appear on the surface of the white SPAR. This life, only the early repair of the Yellow pole, actually let the white SPAR appeared changes. It shows that it is not the strength of true qi at all, but the attribute of true qi."                     //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    For example, a warrior with the mark of fire works best with a psionic crystal of fire, allowing him to triple his training speed. With ordinary psionic crystals, you can only practice twice as fast.                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Ninety percent of all psionic crystals in nature have no properties. Like 90% of martial artists, they can only inspire the mark of martial arts without attributes.                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "Is it possible that the mark of divine force that I opened also possesses some property that fits neatly with this chronolite? Wait a minute, what is a chronolite?"                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen was the son of Emperor Ming in his last life, so he had a wide range of knowledge and heard of many psionic crystals of attributes, such as red flame psionic crystals, ice psionic crystals, lightning psionic crystals, evil blood psionic crystals... However, one has never heard of a psionic crystal as a property of space and time.    //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Because time and space are beyond the control of human beings, even gods cannot shake time and space, they must follow the rules of time and space.                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    When Zhang Ruochen is still very puzzled, the surface of the space-time SPAR emerges a group of halo, into a whirlpool.                                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    The whirlpool grew larger and larger, wrapping Zhang Ruochen's body.                                                                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen only feels a while the world is spinning, the next moment, he came to a closed space, heavy fall on the hard ground.                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Fortunately, he completed the pulp washing and pulse flushing, reaching the early stage of the Yellow Pole, the body strengthened a lot. With his formerly frail body, the fall would have killed him.                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen got up from the ground, moved his aching muscles and bones, and began to observe the space around him.                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    The space is completely enclosed with no Windows or doors in sight. The height of the space is about ten meters, and the length and width are about ten meters.                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "How did this happen? Where did I come in? Where is this? Yi! There is a stone platform!"                                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    In the whole space, there is only one stone platform.                                                                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    On the platform lay a rolled-up picture, a silver iron book. There was nothing else!                                                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen took the lead to take that painting, but, that painting is very heavy, like and stone into one, no matter how much power Zhang Ruochen use, the scroll also did not move.                                                                                                                                                                      //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Since the picture scroll can not be picked up, also the picture scroll can not be opened, Zhang Ruochen can only give up temporarily, and then stare at that thin silver iron book.                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    On the surface of the silver iron book were written four words: "The Lexicon of Time and Space!"                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    This time, Zhang Ruochen is prepared to run the whole body, the power of the whole body are mobilized, the first page of the "time and space Lexicon" opened.                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "So... Easy?"                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    The Lexicon of Time and Space is very easy to read.                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen xing xing however shook his head, stop running true gas, will "time and space midian" pick up, hold in both hands, carefully read.                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    The first page of the Chrono Lexicon is not a practice lexicon, but a record of the master of the chrono SPAR, the Holy Monk Xumi.                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    After zhang Ruochen read the notes of the holy monk, he finally understood everything.                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "I opened the original shenwu mark, turned out to be time and space Shenwu mark. According to the holy Monk Xumi, none of the hundreds of millions of people can open the mark of time and space. There have only been two men since ancient times, and I make three."                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "The Holy Monk Xumi was the second to open the seal of time and space, but according to the time he recorded in the Time and Space Lexicon, he died more than 100,000 years ago. More than 100,000 years ago, that was the Middle Ages, too far away from now."                                                                                              //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    The space where Zhang Ruochen is now is the inner space of the space-time SPAR.                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    The speed of time flowing in inner space is completely different from that in the outside world.                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen exulted, excited: "three days in the inside of the practice, the outside of the past one day, is not more than others out of thin air three times the practice time? That's great."                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen wanted to read the second page of the Time and Space Lexicon, but no matter what method he used, he could not turn the second page.                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "It won't open again."                                                                                                                                                                                                                                                                                                                                       //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen had a kind of impulse to throw the "Time and Space Lexicon" on the ground, suddenly, he looked at the first page of the last row there is a line of small characters.                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "Practice to the yellow pole small pole, the real gas into the scroll, you can open the scroll."                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen stared at the scroll again, the heart guess, the scroll must have recorded some mysterious skills, perhaps with the practice of time and space.                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "Practice hard and strive to break through to the minor pole as soon as possible. Let's see, what secret is hidden inside the picture scroll?"                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    The "minor Pole" is the fourth minor boundary of the yellow Pole, followed by the middle pole, the great Pole, and the great perfection.                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen's stomach spread a feeling of hunger, immediately from the space-time stone inside the space temporarily back to his room.                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    He tightly pinched the space-time SPAR in his hands, with this piece of SPAR, there is a greater grasp in three months to practice to the late yellow Pole.                                                                                                                                                                                                  //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen, Concubine Lin and the maid Cloud were sitting together for breakfast.                                                                                                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Food, just white rice and steamed bread, no meat at all.                                                                                                                                                                                                                                                                                                     //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    For the warrior, the energy consumption is much greater than ordinary people, food is very important.                                                                                                                                                                                                                                                        //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Other princes and princes who opened the mark of divine force ate "blood Dan" made by the blood of wild beasts every day, and had long since stopped eating ordinary food.                                                                                                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Take a grain of xue Dan, can supplement the whole day's physical energy consumption, even if the training of boxing, fencing skills for a day, will not feel hungry.                                                                                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Moreover, taking Xuedan can enhance blood qi, strengthen the military body and increase the physical strength.                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    If Zhang eats only white rice and steamed bread, even eight meals a day are far from enough for his body.                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    "Son Chen, you have now opened the mark of divine force, and can no longer eat ordinary food. You take these ten blood Dan first, if not enough, the mother is thinking of other ways." Concubine Lin took out a jade vase and handed it to Zhang Ruochen.                                                                                                   //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Zhang Ruochen is eating steamed bread, did not think of Lin Fei was able to take out ten red Dan, some confused way: "dear, five silver coins to buy a red Dan, ten red Dan is fifty silver coins, where do you come so much money?"                                                                                                                         //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Concubine Lin smiled and said, "Your mother always has a way."                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Maid Cloud son station in Lin Fei behind, way: "the empress is the most favorite step shake jinchai sold, just went to Dan city for ten blood Dan!"                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//    Princess Lin gently stared at cloud, as if to blame her mouth, and then said: "Dust, you don't think much, as long as you can cultivate into a real warrior, your mother even if all the ornaments sold, will support you to cultivate."                                                                                                                     //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
//                                                                                                                                                                                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TASATSC is ERC721Creator {
    constructor() ERC721Creator("Time and space and the secret code", "TASATSC") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}