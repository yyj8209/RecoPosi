function [categoryClassifier, confMatrix] = ImageCategoryClassification
%% Image Category Classification Using Bag of Features
% This example shows how to use a bag of features approach for image category 
% classification. This technique is also often referred to as bag of words. Visual 
% image categorization is a process of assigning a category label to an image 
% under test. Categories may contain images representing just about anything, 
% for example, dogs, cats, trains, boats.

%% Load Image Sets
% Instead of operating on the entire Caltech 101 set, which can be time consuming, 
% use three categories: 58ʽ, 72ʽ, and 79ʽ. Note that for the bag of 
% features approach to be effective, majority of each image's area must be occupied 
% by the subject of the category, for example, an object or a type of scene.

rootFolder = '.\TrainImage';
%% 
% Construct an ImageDatastore based on the following categories from Caltech 
% 101: '58ʽ', '72ʽ', '79ʽ'. Use |imageDatastore| to help you manage 
% the data. Since |imageDatastore| operates on image file locations, and therefore 
% does not load all the images into memory, it is safe to use on large image collections. 

categories = {'58ʽ', '72ʽ', '79ʽ'};
imds = imageDatastore(fullfile(rootFolder, categories), 'LabelSource', 'foldernames');
%% 
% You can easily inspect the number of images per category as well as category 
% labels as shown below:

tbl = countEachLabel(imds)
%% 
% Note that the labels were derived from directory names used to construct 
% the ImageDatastore, but can be customized by manually setting the Labels property 
% of the ImageDatastore object.
%% Prepare Training and Validation Image Sets
% Since |imds| above contains an unequal number of images per category, let's 
% first adjust it, so that the number of images in the training set is balanced.

minSetCount = min(tbl{:,2}); % determine the smallest amount of images in a category

% Use splitEachLabel method to trim the set.
imds = splitEachLabel(imds, minSetCount, 'randomize');

% Notice that each set now has exactly the same number of images.
countEachLabel(imds)
%% 
% Separate the sets into training and validation data. Pick 30% of images 
% from each set for the training data and the remainder, 70%, for the validation 
% data. Randomize the split to avoid biasing the results.

[trainingSet, validationSet] = splitEachLabel(imds, 0.8, 'randomize');
%% 
% The above call returns two imageDatastore objects ready for training and 
% validation tasks. Below, you can see example images from the three categories 
% included in the training data.

% Find the first instance of an image for each category
% Mine58 = find(trainingSet.Labels == '58ʽ', 1);
% Mine72 = find(trainingSet.Labels == '72ʽ', 1);
% Mine79 = find(trainingSet.Labels == '79ʽ', 1);

% figure
% 
% subplot(1,3,1);
% imshow(readimage(trainingSet,58ʽ))
% subplot(1,3,2);
% imshow(readimage(trainingSet,72ʽ))
% subplot(1,3,3);
% imshow(readimage(trainingSet,79ʽ))
%% Create a Visual Vocabulary and Train an Image Category Classifier
% Bag of words is a technique adapted to computer vision from the world of natural 
% language processing. Since images do not actually contain discrete words, we 
% first construct a "vocabulary" of  <matlab:doc('extractFeatures'); SURF> features 
% representative of each image category.
% 
% This is accomplished with a single call to |bagOfFeatures| function, which:
% 
% # extracts SURF features from all images in all image categories
% # constructs the visual vocabulary by reducing the number of features through 
% quantization of feature space using K-means clustering

bag = bagOfFeatures(trainingSet);
%% 
% Additionally, the bagOfFeatures object provides an |encode| method for 
% counting the visual word occurrences in an image. It produced a histogram that 
% becomes a new and reduced representation of an image.

% img = readimage(imds, 1);
% featureVector = encode(bag, img);

% % Plot the histogram of visual word occurrences
% figure
% bar(featureVector)
% title('Visual word occurrences')
% xlabel('Visual word index')
% ylabel('Frequency of occurrence')
%% 
% This histogram forms a basis for training a classifier and for the actual 
% image classification. In essence, it encodes an image into a feature vector. 
% 
% Encoded training images from each category are fed into a classifier training 
% process invoked by the |trainImageCategoryClassifier| function. Note that this 
% function relies on the multiclass linear SVM classifier from the Statistics 
% and Machine Learning Toolbox?.

categoryClassifier = trainImageCategoryClassifier(trainingSet, bag);
%% 
% The above function utilizes the |encode| method of the input |bag| object 
% to formulate feature vectors representing each image category from the  |trainingSet|.
%% Evaluate Classifier Performance
% Now that we have a trained classifier, |categoryClassifier|, let's evaluate 
% it. As a sanity check, let's first test it with the training set, which should 
% produce near perfect confusion matrix, i.e. ones on the diagonal.

% confMatrix = evaluate(categoryClassifier, trainingSet);
%% 
% Next, let's evaluate the classifier on the validationSet, which was not 
% used during the training. By default, the |evaluate| function returns the confusion 
% matrix, which is a good initial indicator of how well the classifier is performing.

confMatrix = evaluate(categoryClassifier, validationSet);

% Compute average accuracy
mean(diag(confMatrix));
%% 
% Additional statistics can be derived using the rest of arguments returned 
% by the evaluate function. See help for |imageCategoryClassifier/evaluate|. You 
% can tweak the various parameters and continue evaluating the trained classifier 
% until you are satisfied with the results.
%% Try the Newly Trained Classifier on Test Images
% You can now apply the newly trained classifier to categorize new images.

% img = imread(fullfile(rootFolder, 'test', 'IMG_20191109_101545.jpg'));
% [labelIdx, scores] = predict(categoryClassifier, img);
% 
% % Display the string label
% categoryClassifier.Labels{labelIdx}
%% 
% _Copyright 2014 The MathWorks, Inc._