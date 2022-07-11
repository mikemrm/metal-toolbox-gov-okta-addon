FROM golang:1.18 as builder

# Create and change to the app directory.
WORKDIR /app

# Setup dependencies to auth inside docker
ARG ACTIONS_BOT_GITHUB_PAT
ENV ACTIONS_BOT_GITHUB_PAT=${ACTIONS_BOT_GITHUB_PAT}
RUN git config --global url."https://${ACTIONS_BOT_GITHUB_PAT}:x-oauth-basic@github.com/equinixmetal".insteadOf "https://github.com/equinixmetal"
RUN git config --global url."https://${ACTIONS_BOT_GITHUB_PAT}:x-oauth-basic@github.com/packethost".insteadOf "https://github.com/packethost"
ENV GOPRIVATE=go.equinixmetal.net

# Retrieve application dependencies using go modules.
# Allows container builds to reuse downloaded dependencies.
COPY go.* ./
RUN go mod download

# Copy local code to the container image.
COPY . ./

# Build the binary.
# -mod=readonly ensures immutable go.mod and go.sum in container builds.
RUN CGO_ENABLED=0 GOOS=linux go build -mod=readonly -v -o addon

# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM gcr.io/distroless/static

# Copy the binary to the production image from the builder stage.
COPY --from=builder /app/addon /addon

# Run the web service on container startup.
ENTRYPOINT ["/addon"]
CMD ["serve"]