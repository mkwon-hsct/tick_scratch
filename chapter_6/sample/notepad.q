/
* @file notepad.q
* @overview Executed commands in Chapter6.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Section5                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// RDB1
tables[]

// User Matew
q).cmng_api.register_as_producer[MY_ACCOUNT_NAME; `bible]

// User James
q).cmng_api.register_as_consumer[MY_ACCOUNT_NAME; `bible; `esther`oracle]

// User Mattew
q).cmng_api.publish[`bible; `esther; `MESSAGE_BOX; enlist "Vashti refused to come to the banquet of Ahasuerus."]
q).cmng_api.publish[`bible; `oracle; `MESSAGE_BOX; enlist "Peter threw away a net and a boat and followed Jesus."]
q).cmng_api.publish[`bible; `esther; `MESSAGE_BOX; enlist "Vashti was ousted from the queen."]
q).cmng_api.publish[`bible; `esther; `MESSAGE_BOX; enlist "Esther was selected as the new queen."]
q).cmng_api.publish[`bible; `oracle; `MESSAGE_BOX; enlist "Peter went to the sea and did fishing to pay the tax for the shrine."]

// RDB1
q)select from MESSAGE_BOX

// RDB2
q)select from MESSAGE_BOX

// User Mattew
q)CONNECTION
q)-25!(7 8i; (`.cmng_api.update; `MESSAGE_BOX; (.z.p+01:00:00; `oracle; MY_ACCOUNT_NAME; enlist "Levy was evangelized by Jesus.")))

// RDB1
q)select from MESSAGE_BOX

// RDB2
q)select from MESSAGE_BOX

// Intra-day HDB
q)select from MESSAGE_BOX
q)select from CALL

// Log Replayer
q)EOD_TIME: 15i

// User Mattew
q).cmng_api.publish[`bible; `genesis; `MESSAGE_BOX; enlist "Seven fat and sleek cows, then seven gaunt and thin cows."]
q).cmng_api.publish[`bible; `genesis; `MESSAGE_BOX; enlist "Seven full and good ears, then seven withered, thin and blighted ears."]
q)-25!(7 8i; (`.cmng_api.update; `MESSAGE_BOX; (.z.p+02:00:00; `genesis; MY_ACCOUNT_NAME; enlist "Seven years of plenty, then seven years of famine.")))

// RDB1
q)select from MESSAGE_BOX
q)select from CALL

// RDB2
q)select from MESSAGE_BOX
q)select from CALL

// HDB
q)select from MESSAGE_BOX
q)select from CALL

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Section6                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// User James
q).cmng_api.register_as_consumer[MY_ACCOUNT_NAME; `bible; `apostles`esther]
q).cmng_api.start_private_chat[`james; `mattew; 1b; `]
q).cmng_api.publish_private[`mattew; "q language is simple for me by virtue of this book."]

// User Mattew
q).cmng_api.register_as_producer[MY_ACCOUNT_NAME; `bible]
q).cmng_api.publish_private[`james; "Glad to hear, James."]
q).cmng_api.publish_private[`james; "Do you want to write a book yourself?"]

// James
q).cmng_api.publish_private[`mattew; "Someday. I can do whatever in the lord."]

// Mattew
q).cmng_api.publish[`bible; `esther; `MESSAGE_BOX; "Thus shall it be done to the man whom the king delights to honor!!"]
q).cmng_api.publish[`bible; `genesis; `MESSAGE_BOX; "Isaac trembled violently."]
q).cmng_api.publish[`bible; `esther; `MESSAGE_BOX; "The anger of Ahasuerus was kindled against Haman. He is undone."]

// User Mattew
q)raze .cmng_api.call[GATEWAY_CHANNEL;`query; `.gateway.query; ((2021.08.29D05:00:01; 2021.08.29D12:30:00); `oracle`esther; "{[args;topics;time_range] ?[args[0]; ((in; `topic; enlist topics); (within; `time; time_range)); args[1]; args[2]]}"; (`MESSAGE_BOX; 0b; ()); {[results] (uj/) results}); 0b]
q)raze .cmng_api.call[GATEWAY_CHANNEL;`query; `.gateway.query; ((2021.08.25D14:00:00; 2021.08.29D12:30:00); `oracle`esther; "{[args;topics;time_range] ?[args[0]; ((in; `topic; enlist topics); (within; `time; time_range)); args[1]; args[2]]}"; (`MESSAGE_BOX; 0b; ()); {[results] (uj/) results}); 0b]

// Resource Manager
DATABASE_AVAILABILITY

// User Mattew
q)raze .cmng_api.call[GATEWAY_CHANNEL;`query; `.gateway.query; ((2021.08.29D05:00:01; 2021.08.29D12:30:00); enlist `query; "{[args;topics;time_range] ?[args[0]; ((in; `topic; enlist topics); (within; `time; time_range)); args[1]; args[2]]}"; (`CALL; 0b; ()); {[results] (uj/) results}); 0b]

// Execute with kdb+ Studio //------------------------------/

// User Mattew
q)raze .cmng_api.call[GATEWAY_CHANNEL;`query; `.gateway.query; ((2021.08.29D00:00:01; 2021.08.29D12:30:00); `oracle`esther; "{[args;topics;time_range] system \"sleep 10\"; ?[args[0]; ((in; `topic; enlist topics); (within; `time; time_range)); args[1]; args[2]]}"; (`MESSAGE_BOX; 0b; ()); {[results] (uj/) results}); 0b]

// User James
q)raze .cmng_api.call[GATEWAY_CHANNEL;`query; `.gateway.query; ((2021.08.25D14:00:01; 2021.08.29D12:30:00); enlist `all; "{[args;topics;time_range] ?[args[0]; ((in; `topic; enlist topics); (within; `time; time_range)); args[1]; args[2]]}"; (`MESSAGE_BOX; 0b; ()); {[results] (uj/) results}); 0b]

// Gateway
q)QUERY_QUEUE

// End //----------------------------------------------------/

// Resource Manager
DATABASE_AVAILABILITY

// User Mattew
q)search_message[`oracle`esther; (2021.08.25D14:00:01; 2021.08.29D10:00:00); ()]
q)search_message[enlist `all; (2021.08.25D14:00:01; 2021.08.29D10:00:00); ()]

// User Mattew
q)search_message[enlist `all; (2021.08.25D14:00:01; 2021.08.29D10:00:00); enlist[`keyword]!enlist "*Ahasuerus*"]
q)search_message[enlist `user_chat; (2021.08.25D14:00:01; 2021.08.29D10:00:00); enlist[`keyword]!enlist "*Gateway*"]
q)search_message[enlist `user_chat; (2021.08.25D14:00:01; 2021.08.29D10:00:00); `sender`keyword!(`mattew; "*Gateway*")]

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Section7                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Mattew
q).cmng_api.start_private_chat[`mattew; `james; 1b; `]
q).cmng_api.register_as_producer[MY_ACCOUNT_NAME; `bible]
q).cmng_api.publish_private[`james; "Do you know some creatures are called by different names accordint to the size?"]

// User James
q).cmng_api.publish_private[`mattew; "Hi Mattew, I did not know that. can you give me an example?"]

// User Mattew
q).cmng_api.publish_private[`james; "For example, a vulture, hawk and eagle belong to the same spieces but a vulture is the smallest and an eagle is the largest."]

// User James
q).cmng_api.publish_private[`mattew; "Interesting. By the way, Paul said he became a poor person to the poor and a rich man to the rich."]
q).cmng_api.publish_private[`mattew; "Does that mean Paul could change his appearance like a chameleon?"]

// User Mattew
q).cmng_api.publish_private[`james; "No, he meant he talked to people according to situations each person is facing."]

// User James
q).cmng_api.publish_private[`mattew; "I see. So the lives of people are different from each other but all problems find their answers by the truth!"]
q).cmng_api.publish_private[`mattew; "Have you already sent to today's scripture?"]

// User Mattew
q).cmng_api.publish_private[`james; "Sec. I will send a scripture from Corinthians."]
q).cmng_api.publish[`bible; `corinthians; `MESSAGE_BOX; "Death is swallowed up in victory. O death, where is thy victory? O death, where is thy sting?"]

// RDB2
q)ALERT
