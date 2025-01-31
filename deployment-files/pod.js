const podConfig = {  
    apiVersion: "v1",  
    kind: "Pod",  
    metadata: {  
      name: "my_pod",  
      labels: {  
        type: "fe"  
      }  
    },  
    spec: {  
      containers: [ 
        {  
          name: "nginx_container",  
          image: "nginx"  
        }  
      ]  
    }  
  };  
  