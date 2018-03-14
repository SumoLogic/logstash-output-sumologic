#!/bin/bash

if [ "$1" = "keep-alive" ]; then
                                                                           
  echo "This is an idle script (infinite loop) to keep container alive."
  echo "Using 'docker exec -it <container ID> /bin/bash' to connect."

  cleanup ()
  {
    kill -s SIGTERM $!
    exit 0
  }

  trap cleanup SIGINT SIGTERM

  while [ 1 ]
  do
    sleep 60 &
    wait $!
  done

else

  bash

fi