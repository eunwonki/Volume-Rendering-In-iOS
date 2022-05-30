# Volume-Rendering-In-iOS
Implement volume-rendering for patient-data on iOS.
   
     
### Tech
- Metal Shader (Graphic)
- SceneKit (Scene Graph)


### Source Project
[Unity Volume Rendering](https://github.com/mlavik1/UnityVolumeRendering)


## How To Run in your Local 
   
### At First,
You should set git-lfs setting.   
Because raw data file is so bigger than supported in git.

install git-lfs first,
```
brew install git-lfs
```

and set git lfs on in your local
```
git-lfs install
```

and pull lfs from server
```
git lfs pull
``` 
       
### Screenshot

|surface rendring|direct volume rendering|maximum intensity projection|
|-|-|-|
|![](https://github.com/eunwonki/Metal-Based-Volume-Rendering-In-iOS/blob/main/Screenshot/1.jpeg?raw=true)|![](https://github.com/eunwonki/Metal-Based-Volume-Rendering-In-iOS/blob/main/Screenshot/2.jpeg?raw=true)|![](https://github.com/eunwonki/Metal-Based-Volume-Rendering-In-iOS/blob/main/Screenshot/3.jpeg?raw=true)|
     
       
#### Direct Volume Rendering    
|CT-Coronary-Arteries|CT-Lung|
|- |-|
|![](https://github.com/eunwonki/Metal-Based-Volume-Rendering-In-iOS/blob/main/Screenshot/5.png?raw=true)|![](https://github.com/eunwonki/Metal-Based-Volume-Rendering-In-iOS/blob/main/Screenshot/4.png?raw=true)|